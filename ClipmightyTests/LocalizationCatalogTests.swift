import XCTest
@testable import Clipmighty

final class LocalizationCatalogTests: XCTestCase {
    func testAllLocalizationEntriesArePresentInStringCatalog() throws {
        let catalog = try loadStringCatalog()
        let missingKeys = L10n.allEntries
            .map(\.key)
            .filter { catalog.strings[$0] == nil }

        XCTAssertTrue(missingKeys.isEmpty, "Missing Localizable.xcstrings keys: \(missingKeys)")
    }

    func testLocalizationEntriesHaveEnglishValues() throws {
        let catalog = try loadStringCatalog()
        let mismatchedEntries = L10n.allEntries.compactMap { entry -> String? in
            guard let value = catalog.strings[entry.key]?.localizations["en"]?.stringUnit.value else {
                return entry.key
            }

            return value == entry.defaultValue ? nil : entry.key
        }

        XCTAssertTrue(mismatchedEntries.isEmpty, "English values do not match source defaults: \(mismatchedEntries)")
    }

    func testLocalizationEntriesHaveTranslatorComments() throws {
        let catalog = try loadStringCatalog()
        let missingComments = L10n.allEntries
            .map(\.key)
            .filter { key in
                guard let comment = catalog.strings[key]?.comment else {
                    return true
                }

                return comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }

        XCTAssertTrue(missingComments.isEmpty, "Missing translator comments: \(missingComments)")
    }

    func testLocalizationKeysAreUniqueAndNonEmpty() {
        let keys = L10n.allEntries.map(\.key)

        XCTAssertFalse(keys.contains(""))
        XCTAssertEqual(Set(keys).count, keys.count, "Localization keys must be unique.")
    }

    func testCatalogCoversPrimaryUserFacingSurfaces() {
        let keys = Set(L10n.allEntries.map(\.key))
        let expectedKeys = [
            "app.menu.title",
            "clipboard.search.placeholder",
            "overlay.title",
            "settings.general.tab",
            "settings.rules.tab",
            "settings.sync.tab",
            "settings.about.tab",
            "onboarding.welcome.title",
            "support.bugReport.subject",
            "shortcut.validation.invalid.title"
        ]

        XCTAssertTrue(expectedKeys.allSatisfy(keys.contains), "Primary UI localization keys are missing.")
    }

    private func loadStringCatalog() throws -> StringCatalog {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let projectRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let catalogURL = projectRoot
            .appendingPathComponent("Clipmighty")
            .appendingPathComponent("Resources")
            .appendingPathComponent("Localizable.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        return try JSONDecoder().decode(StringCatalog.self, from: data)
    }
}

private struct StringCatalog: Decodable {
    let strings: [String: StringCatalogEntry]
}

private struct StringCatalogEntry: Decodable {
    let comment: String?
    let localizations: [String: StringCatalogLocalization]
}

private struct StringCatalogLocalization: Decodable {
    let stringUnit: StringCatalogStringUnit
}

private struct StringCatalogStringUnit: Decodable {
    let value: String
}
