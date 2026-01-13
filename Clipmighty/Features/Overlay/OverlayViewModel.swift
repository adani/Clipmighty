import SwiftUI
import SwiftData
import Combine

@Observable
class OverlayViewModel {
    var selectedIndex: Int = 0
    var items: [ClipboardItem] = []
    var viewID: UUID = UUID()
    var showCopiedToast: Bool = false

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
            viewID = UUID() // Force complete view refresh
            if items.isEmpty {
                print("[OverlayViewModel] Warning: No items found in SwiftData.")
            }
        } catch {
            print("[OverlayViewModel] Failed to fetch items: \(error)")
        }
    }

    func reset() {
        selectedIndex = 0
        viewID = UUID()
        showCopiedToast = false
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

    func getSelectedItem() -> ClipboardItem? {
        guard items.indices.contains(selectedIndex) else { return nil }
        return items[selectedIndex]
    }
}
