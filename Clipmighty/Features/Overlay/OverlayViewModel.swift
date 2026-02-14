import SwiftUI
import SwiftData
import Combine

@Observable
class OverlayViewModel {
    var selectedIndex: Int = 0
    var items: [ClipboardItem] = []
    var viewID: UUID = UUID()
    var isAccessibilityTrusted: Bool = false
    var visibleIndexRange: ClosedRange<Int>?

    // Dependencies
    var modelContext: ModelContext?

    func loadItems() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<ClipboardItem>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        // Limit for performance in the overlay
        var fetchDescriptor = descriptor
        fetchDescriptor.fetchLimit = 50

        do {
            print("[OverlayViewModel] Fetching items...")
            items = try context.fetch(fetchDescriptor)
            print("[OverlayViewModel] Fetched \(items.count) items.")
            selectedIndex = 0
            visibleIndexRange = nil
            viewID = UUID() // Force complete view refresh
            if items.isEmpty {
                print("[OverlayViewModel] Warning: No items found in SwiftData.")
            }
        } catch {
            print("[OverlayViewModel] Failed to fetch items: \(error)")
        }
    }

    func checkAccessibility() {
        isAccessibilityTrusted = PasteHelper.canPaste()
    }

    func reset() {
        selectedIndex = 0
        visibleIndexRange = nil
        viewID = UUID()
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
}
