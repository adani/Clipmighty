import SwiftData
import XCTest
@testable import Clipmighty

final class PinnedItemsBehaviorTests: XCTestCase {
    private let retentionKey = "retentionDuration"
    private let keepPinnedKey = "keepPinnedItemsOnCleanup"
    private var inMemoryContainers: [ModelContainer] = []

    private var previousRetentionValue: Any?
    private var previousKeepPinnedValue: Any?

    override func setUp() {
        super.setUp()
        previousRetentionValue = UserDefaults.standard.object(forKey: retentionKey)
        previousKeepPinnedValue = UserDefaults.standard.object(forKey: keepPinnedKey)
    }

    override func tearDown() {
        if let previousRetentionValue {
            UserDefaults.standard.set(previousRetentionValue, forKey: retentionKey)
        } else {
            UserDefaults.standard.removeObject(forKey: retentionKey)
        }

        if let previousKeepPinnedValue {
            UserDefaults.standard.set(previousKeepPinnedValue, forKey: keepPinnedKey)
        } else {
            UserDefaults.standard.removeObject(forKey: keepPinnedKey)
        }

        inMemoryContainers.removeAll()

        super.tearDown()
    }

    @MainActor
    func testPurgeOldItems_keepsPinnedItems_whenKeepPinnedEnabled() throws {
        let context = try makeInMemoryContext()
        UserDefaults.standard.set(1, forKey: retentionKey)
        UserDefaults.standard.set(true, forKey: keepPinnedKey)

        let oldDate = Date().addingTimeInterval(-3600)
        context.insert(ClipboardItem(content: "old pinned", timestamp: oldDate, isPinned: true))
        context.insert(ClipboardItem(content: "old unpinned", timestamp: oldDate, isPinned: false))
        try context.save()

        ClipmightyApp.purgeOldItems(context: context)

        let items = try context.fetch(FetchDescriptor<ClipboardItem>())
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.content, "old pinned")
        XCTAssertEqual(items.first?.isPinned, true)
    }

    @MainActor
    func testPurgeOldItems_deletesPinnedItems_whenKeepPinnedDisabled() throws {
        let context = try makeInMemoryContext()
        UserDefaults.standard.set(1, forKey: retentionKey)
        UserDefaults.standard.set(false, forKey: keepPinnedKey)

        let oldDate = Date().addingTimeInterval(-3600)
        context.insert(ClipboardItem(content: "old pinned", timestamp: oldDate, isPinned: true))
        context.insert(ClipboardItem(content: "old unpinned", timestamp: oldDate, isPinned: false))
        try context.save()

        ClipmightyApp.purgeOldItems(context: context)

        let items = try context.fetch(FetchDescriptor<ClipboardItem>())
        XCTAssertEqual(items.count, 0)
    }

    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([ClipboardItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        inMemoryContainers.append(container)
        return ModelContext(container)
    }
}
