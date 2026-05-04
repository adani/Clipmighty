import SwiftUI
import SwiftData
import Combine

enum PinToggleResult: Equatable {
    case pinned
    case unpinned
    case failed
}

@Observable
class OverlayViewModel {
    var selectedIndex: Int = 0
    var items: [ClipboardItem] = []
    var searchQuery: String = ""
    var viewID: UUID = UUID()
    var isAccessibilityTrusted: Bool = false
    var visibleIndexRange: ClosedRange<Int>?

    // Dependencies
    var modelContext: ModelContext?
    private var allItems: [ClipboardItem] = []

    func loadItems() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<ClipboardItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            print("[OverlayViewModel] Fetching items...")
            let fetchedItems = try context.fetch(descriptor)
            refreshSearchIndexesIfNeeded(for: fetchedItems, context: context)
            allItems = sortedWithPinnedFirst(fetchedItems)
            applySearchQuery(searchQuery)
            print("[OverlayViewModel] Fetched \(allItems.count) items.")
            selectedIndex = 0
            visibleIndexRange = nil
            viewID = UUID() // Force complete view refresh
            if allItems.isEmpty {
                print("[OverlayViewModel] Warning: No items found in SwiftData.")
            }
        } catch {
            print("[OverlayViewModel] Failed to fetch items: \(error)")
        }
    }

    @discardableResult
    func togglePinForSelectedItem() -> PinToggleResult {
        guard let context = modelContext,
              items.indices.contains(selectedIndex) else {
            return .failed
        }

        let selectedItem = items[selectedIndex]
        let selectedItemID = selectedItem.id
        selectedItem.isPinned.toggle()
        let isPinnedAfterToggle = selectedItem.isPinned
        selectedItem.timestamp = Date()

        do {
            try context.save()
            allItems = sortedWithPinnedFirst(allItems)
            applySearchQuery(searchQuery, preferredItemID: selectedItemID)
            if let newIndex = items.firstIndex(where: { $0.id == selectedItemID }) {
                selectedIndex = newIndex
            }
            viewID = UUID()
            return isPinnedAfterToggle ? .pinned : .unpinned
        } catch {
            print("[OverlayViewModel] Failed to toggle pin: \(error)")
            return .failed
        }
    }

    func checkAccessibility() {
        isAccessibilityTrusted = PasteHelper.canPaste()
    }

    func reset() {
        selectedIndex = 0
        searchQuery = ""
        visibleIndexRange = nil
        items = allItems
        viewID = UUID()
    }

    func applySearchQuery(_ query: String) {
        applySearchQuery(query, preferredItemID: nil)
    }

    @discardableResult
    func handleSearchCharacter(_ character: String) -> Bool {
        guard isSearchCharacter(character) else {
            return false
        }

        applySearchQuery(searchQuery + character)
        return true
    }

    @discardableResult
    func deleteLastSearchCharacter() -> Bool {
        guard !searchQuery.isEmpty else {
            return true
        }

        var nextQuery = searchQuery
        nextQuery.removeLast()
        applySearchQuery(nextQuery)
        return true
    }

    func moveSelectionDown() {
        if selectedIndex < items.count - 1 {
            selectedIndex += 1
        }
    }

    func moveSelectionUp() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
    }

    func moveSelectionPageDown() {
        guard !items.isEmpty else { return }

        if let visibleIndexRange {
            selectedIndex = min(visibleIndexRange.upperBound + 1, items.count - 1)
            return
        }

        selectedIndex = min(selectedIndex + 1, items.count - 1)
    }

    func moveSelectionPageUp() {
        guard !items.isEmpty else { return }

        if let visibleIndexRange {
            selectedIndex = max(visibleIndexRange.lowerBound - 1, 0)
            return
        }

        selectedIndex = max(selectedIndex - 1, 0)
    }

    func moveSelectionToFirst() {
        guard !items.isEmpty else { return }
        selectedIndex = 0
    }

    func moveSelectionToLast() {
        guard !items.isEmpty else { return }
        selectedIndex = items.count - 1
    }

    func getSelectedItem() -> ClipboardItem? {
        guard !items.isEmpty else { return nil }

        if selectedIndex < 0 {
            selectedIndex = 0
        } else if selectedIndex >= items.count {
            selectedIndex = items.count - 1
        }

        guard items.indices.contains(selectedIndex) else { return nil }
        return items[selectedIndex]
    }

    private func sortedWithPinnedFirst(_ sourceItems: [ClipboardItem]) -> [ClipboardItem] {
        let pinnedItems = sourceItems
            .filter(\.isPinned)
            .sorted(by: { $0.timestamp > $1.timestamp })
        let unpinnedItems = sourceItems
            .filter { !$0.isPinned }
            .sorted(by: { $0.timestamp > $1.timestamp })

        return pinnedItems + unpinnedItems
    }

    private func applySearchQuery(_ query: String, preferredItemID: UUID?) {
        let didChangeQuery = searchQuery != query
        searchQuery = query

        let normalizedQuery = FuzzyStringMatcher.normalized(query)
        if normalizedQuery.isEmpty {
            items = allItems
        } else {
            items = allItems.filter { item in
                FuzzyStringMatcher.matches(
                    normalizedQuery: normalizedQuery,
                    inNormalizedCandidate: item.searchIndex
                )
            }
        }

        if let preferredItemID,
           let preferredIndex = items.firstIndex(where: { $0.id == preferredItemID }) {
            selectedIndex = preferredIndex
        } else if didChangeQuery {
            selectedIndex = 0
        } else {
            selectedIndex = min(max(selectedIndex, 0), max(items.count - 1, 0))
        }

        visibleIndexRange = nil
        viewID = UUID()
    }

    private func refreshSearchIndexesIfNeeded(for sourceItems: [ClipboardItem], context: ModelContext) {
        var didUpdateIndex = false

        for item in sourceItems {
            let expectedIndex = ClipboardItem.makeSearchIndex(
                content: item.content,
                itemType: item.itemType,
                sourceAppBundleID: item.sourceAppBundleID,
                sourceAppName: item.sourceAppName,
                fileURL: item.fileURL
            )

            if item.searchIndex != expectedIndex {
                item.searchIndex = expectedIndex
                didUpdateIndex = true
            }
        }

        if didUpdateIndex {
            try? context.save()
        }
    }

    private func isSearchCharacter(_ character: String) -> Bool {
        guard character.count == 1,
              let scalar = character.unicodeScalars.first else {
            return false
        }

        return !CharacterSet.controlCharacters.contains(scalar)
    }
}
