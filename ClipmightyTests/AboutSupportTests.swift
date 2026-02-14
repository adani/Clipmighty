import XCTest
@testable import Clipmighty

final class AboutSupportTests: XCTestCase {
    func testVersionDescription_withVersionAndBuild_formatsCorrectly() {
        let info: [String: Any] = [
            "CFBundleShortVersionString": "1.2.3",
            "CFBundleVersion": "45"
        ]

        let description = AboutSupport.versionDescription(infoDictionary: info)

        XCTAssertEqual(description, "Version 1.2.3 (Build 45)")
    }

    func testVersionDescription_withoutBundleInfo_usesFallback() {
        let description = AboutSupport.versionDescription(infoDictionary: nil)

        XCTAssertEqual(description, "Version Unknown")
    }

    func testContactMailURL_usesSupportAddress() {
        let url = AboutSupport.contactMailURL()

        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "mailto")
        XCTAssertEqual(url?.absoluteString.contains("support@nalarin.com"), true)
        XCTAssertEqual(url?.absoluteString.contains("Feedback%20for%20Clipmighty"), true)
    }

    func testBugReportMailURL_usesSupportAddressAndSubject() {
        let url = AboutSupport.bugReportMailURL()

        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "mailto")
        XCTAssertEqual(url?.absoluteString.contains("support@nalarin.com"), true)
        XCTAssertEqual(url?.absoluteString.contains("Bug%20Report%20for%20Clipmighty"), true)
    }

    func testExportSupportLog_createsFileWithExpectedContent() throws {
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        let info: [String: Any] = [
            "CFBundleShortVersionString": "9.9.9",
            "CFBundleVersion": "999"
        ]

        let fileURL = try AboutSupport.exportSupportLog(
            to: tempDirectory,
            infoDictionary: info,
            additionalLines: ["Sample line"]
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(contents.contains("Clipmighty Support Log"))
        XCTAssertTrue(contents.contains("Version 9.9.9 (Build 999)"))
        XCTAssertTrue(contents.contains("Sample line"))
    }

    func testBugReportAppleScript_withAttachment_containsAttachmentStatement() {
        let script = AboutSupport.mailAppleScript(
            to: "support@nalarin.com",
            subject: "Bug Report",
            body: "Body",
            attachmentFileURL: URL(fileURLWithPath: "/tmp/clipmighty.log")
        )

        XCTAssertTrue(script.contains("make new attachment"))
        XCTAssertTrue(script.contains("/tmp/clipmighty.log"))
    }
}