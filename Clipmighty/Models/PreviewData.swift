import Foundation
import SwiftData

@MainActor
struct PreviewData {
    static let container: ModelContainer = {
        let schema = Schema([ClipboardItem.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            insertMockData(context: container.mainContext)
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()

    static func insertMockData(context: ModelContext) {
        // Clear existing data if any (though unlikely in new memory container)
        // ...

        let items = [
            ClipboardItem(
                content: "Hello, world!",
                itemType: .text,
                timestamp: Date(),
                sourceAppName: "TextEdit"
            ),
            ClipboardItem(
                content: "https://www.apple.com",
                itemType: .link,
                timestamp: Date().addingTimeInterval(-60),
                sourceAppName: "Safari"
            ),
            ClipboardItem(
                content: "Significant Text",
                itemType: .text,
                timestamp: Date().addingTimeInterval(-300),
                sourceAppName: "Notes",
                isPinned: true
            ),
            ClipboardItem(
                content: "#FF5733",
                itemType: .color,
                timestamp: Date().addingTimeInterval(-600),
                sourceAppName: "Figma"
            ),
            ClipboardItem(
                content: "Image 1024x768",
                itemType: .image,
                timestamp: Date().addingTimeInterval(-1200),
                sourceAppName: "Preview"
            )
        ]

        for item in items {
            context.insert(item)
        }
    }
}
