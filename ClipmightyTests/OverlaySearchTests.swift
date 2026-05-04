import AppKit
import SwiftData
import XCTest
@testable import Clipmighty

final class OverlaySearchTests: XCTestCase {
    private var inMemoryContainers: [ModelContainer] = []

    override func tearDown() {
        inMemoryContainers.removeAll()
        super.tearDown()
    }

    func testFuzzyMatcherMatchesOrderedCharactersAcrossWordsAndCase() {
        XCTAssertTrue(FuzzyStringMatcher.matches(query: "sfn", in: "Safari Note"))
        XCTAssertTrue(FuzzyStringMatcher.matches(query: "CM", in: "clip mighty"))
        XCTAssertFalse(FuzzyStringMatcher.matches(query: "nfz", in: "Safari Note"))
    }

    func testFuzzyMatcherMatchesSeparatedWordsInsideLinkedInURL() {
        XCTAssertTrue(
            FuzzyStringMatcher.matches(
                query: "linkedin adani arisy",
                in: "https://www.linkedin.com/in/adaniarisy/"
            )
        )
    }

    func testFuzzyMatcherDoesNotScatterMultiWordQueryAcrossUnrelatedText() {
        XCTAssertFalse(
            FuzzyStringMatcher.matches(
                query: "linkedin adani",
                in: "5 silly questions to annoy her Brave Browser"
            )
        )
    }

    func testClipboardItemBuildsNormalizedSearchIndexForContentAndSourceApp() {
        let item = ClipboardItem(
            content: "Résumé Builder",
            sourceAppBundleID: "com.example.Resume",
            sourceAppName: "Safari"
        )

        XCTAssertTrue(item.searchIndex.contains("resume builder"))
        XCTAssertTrue(item.searchIndex.contains("safari"))
        XCTAssertTrue(item.searchIndex.contains("com example resume"))
    }

    @MainActor
    func testOverlayFiltersWithFuzzySearchAndKeepsDefaultSortOrder() throws {
        let context = try makeInMemoryContext()
        let newestDate = Date()
        let middleDate = newestDate.addingTimeInterval(-60)
        let oldestDate = newestDate.addingTimeInterval(-120)

        context.insert(ClipboardItem(content: "Safari private note", timestamp: oldestDate, isPinned: true))
        context.insert(ClipboardItem(content: "Slack final note", timestamp: newestDate))
        context.insert(ClipboardItem(content: "Budget report", timestamp: middleDate))
        try context.save()

        let viewModel = OverlayViewModel()
        viewModel.modelContext = context
        viewModel.loadItems()

        XCTAssertEqual(viewModel.items.map(\.content), [
            "Safari private note",
            "Slack final note",
            "Budget report"
        ])

        viewModel.applySearchQuery("sfn")

        XCTAssertEqual(viewModel.items.map(\.content), [
            "Safari private note",
            "Slack final note"
        ])
        XCTAssertEqual(viewModel.searchQuery, "sfn")
        XCTAssertEqual(viewModel.selectedIndex, 0)
    }

    @MainActor
    func testOverlayFilteringClampsSelectionToFilteredResults() throws {
        let context = try makeInMemoryContext()

        context.insert(ClipboardItem(content: "Alpha"))
        context.insert(ClipboardItem(content: "Beta"))
        try context.save()

        let viewModel = OverlayViewModel()
        viewModel.modelContext = context
        viewModel.loadItems()
        viewModel.selectedIndex = 1

        viewModel.applySearchQuery("alp")

        XCTAssertEqual(viewModel.items.map(\.content), ["Alpha"])
        XCTAssertEqual(viewModel.selectedIndex, 0)
    }

    @MainActor
    func testOverlayTextInputAppendsAndDeletesSearchCharacters() throws {
        let context = try makeInMemoryContext()
        context.insert(ClipboardItem(content: "Alpha"))
        context.insert(ClipboardItem(content: "Beta"))
        try context.save()

        let viewModel = OverlayViewModel()
        viewModel.modelContext = context
        viewModel.loadItems()

        XCTAssertTrue(viewModel.handleSearchCharacter("a"))
        XCTAssertTrue(viewModel.handleSearchCharacter("l"))
        XCTAssertEqual(viewModel.searchQuery, "al")
        XCTAssertEqual(viewModel.items.map(\.content), ["Alpha"])

        XCTAssertTrue(viewModel.deleteLastSearchCharacter())
        XCTAssertEqual(viewModel.searchQuery, "a")
        XCTAssertEqual(viewModel.items.map(\.content).count, 2)
    }

    @MainActor
    func testOverlaySearchFindsLinkedInURLAndExcludesUnrelatedItems() throws {
        let context = try makeInMemoryContext()

        context.insert(ClipboardItem(content: "5 silly questions to annoy her", sourceAppName: "Brave Browser"))
        context.insert(ClipboardItem(content: "Questions", sourceAppName: "Brave Browser"))
        context.insert(ClipboardItem(content: "https://www.linkedin.com/in/adaniarisy/", sourceAppName: "Brave Browser"))
        try context.save()

        let viewModel = OverlayViewModel()
        viewModel.modelContext = context
        viewModel.loadItems()

        viewModel.applySearchQuery("linkedin adani arisy")

        XCTAssertEqual(viewModel.items.map(\.content), ["https://www.linkedin.com/in/adaniarisy/"])
    }

    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([ClipboardItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        inMemoryContainers.append(container)
        return ModelContext(container)
    }
}
