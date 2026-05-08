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
            guard let value = catalog.strings[entry.key]?.localizations?["en"]?.stringUnit.value else {
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

    func testLocalizationEntriesHaveIndonesianTranslations() throws {
        let catalog = try loadStringCatalog()
        let missingTranslations = L10n.allEntries.compactMap { entry -> String? in
            guard let stringUnit = catalog.strings[entry.key]?.localizations?["id"]?.stringUnit else {
                return entry.key
            }

            return stringUnit.state == "translated" && !stringUnit.value.isEmpty ? nil : entry.key
        }

        XCTAssertTrue(missingTranslations.isEmpty, "Missing Indonesian translations: \(missingTranslations)")
    }

    func testIndonesianTranslationsPreserveFormatSpecifiers() throws {
        let catalog = try loadStringCatalog()
        let mismatchedEntries = L10n.allEntries.compactMap { entry -> String? in
            guard let localizedValue = catalog.strings[entry.key]?.localizations?["id"]?.stringUnit.value else {
                return nil
            }

            return formatSpecifiers(in: localizedValue) == formatSpecifiers(in: entry.defaultValue) ? nil : entry.key
        }

        XCTAssertTrue(mismatchedEntries.isEmpty, "Indonesian translations changed format specifiers: \(mismatchedEntries)")
    }

    func testRequestedLocalizationEntriesHaveTranslations() throws {
        let catalog = try loadStringCatalog()

        for locale in requestedLocalizationLocales {
            let missingTranslations = L10n.allEntries.compactMap { entry -> String? in
                guard let stringUnit = catalog.strings[entry.key]?.localizations?[locale]?.stringUnit else {
                    return entry.key
                }

                return stringUnit.state == "translated" && !stringUnit.value.isEmpty ? nil : entry.key
            }

            XCTAssertTrue(
                missingTranslations.isEmpty,
                "Missing \(locale) translations: \(missingTranslations)"
            )
        }
    }

    func testRequestedTranslationsPreserveFormatSpecifiers() throws {
        let catalog = try loadStringCatalog()

        for locale in requestedLocalizationLocales {
            let mismatchedEntries = L10n.allEntries.compactMap { entry -> String? in
                guard let localizedValue = catalog.strings[entry.key]?.localizations?[locale]?.stringUnit.value else {
                    return nil
                }

                return formatSpecifiers(in: localizedValue) == formatSpecifiers(in: entry.defaultValue) ? nil : entry.key
            }

            XCTAssertTrue(
                mismatchedEntries.isEmpty,
                "\(locale) translations changed format specifiers: \(mismatchedEntries)"
            )
        }
    }

    func testProjectSupportsIndonesianLocalization() throws {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let projectRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let projectFileURL = projectRoot
            .appendingPathComponent("Clipmighty.xcodeproj")
            .appendingPathComponent("project.pbxproj")
        let projectContents = try String(contentsOf: projectFileURL)

        XCTAssertTrue(projectContents.contains("\n\t\t\t\tid,\n"), "Clipmighty.xcodeproj must list id as a known region.")
    }

    func testProjectSupportsRequestedLocalizations() throws {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let projectRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let projectFileURL = projectRoot
            .appendingPathComponent("Clipmighty.xcodeproj")
            .appendingPathComponent("project.pbxproj")
        let projectContents = try String(contentsOf: projectFileURL)

        for locale in requestedLocalizationLocales {
            let containsWithoutQuotes = projectContents.contains("\n\t\t\t\t\(locale),\n")
            let containsWithQuotes = projectContents.contains("\n\t\t\t\t\"\(locale)\",\n")
            XCTAssertTrue(
                containsWithoutQuotes || containsWithQuotes,
                "Clipmighty.xcodeproj must list \(locale) as a known region."
            )
        }
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

    private func formatSpecifiers(in value: String) -> [String] {
        let pattern = "%(?:\\d+\\$)?(?:@|d|lld)"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(value.startIndex..<value.endIndex, in: value)

        return regex.matches(in: value, range: range).compactMap { match in
            guard let range = Range(match.range, in: value) else {
                return nil
            }

            return String(value[range])
        }
    }

    private let requestedLocalizationLocales = ["fr-CA", "fr", "de", "ar", "ja", "nl", "ru", "zh-Hans"]
}

private struct StringCatalog: Decodable {
    let strings: [String: StringCatalogEntry]
}

private struct StringCatalogEntry: Decodable {
    let comment: String?
    let localizations: [String: StringCatalogLocalization]?
}

private struct StringCatalogLocalization: Decodable {
    let stringUnit: StringCatalogStringUnit
}

private struct StringCatalogStringUnit: Decodable {
    let state: String
    let value: String
}
