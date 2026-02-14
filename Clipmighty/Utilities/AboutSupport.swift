import AppKit
import Foundation

enum AboutSupport {
    static let supportEmail = "support@nalarin.com"

    static func versionDescription(infoDictionary: [String: Any]? = Bundle.main.infoDictionary) -> String {
        guard let infoDictionary else {
            return "Version Unknown"
        }

        let version = infoDictionary["CFBundleShortVersionString"] as? String
        let build = infoDictionary["CFBundleVersion"] as? String

        if let version, let build {
            return "Version \(version) (Build \(build))"
        }

        if let version {
            return "Version \(version)"
        }

        return "Version Unknown"
    }

    static func contactMailURL() -> URL? {
        let subject = "Feedback for Clipmighty"
        let body = "Hi Clipmighty team,%0A%0A"
        return mailtoURL(subject: subject, body: body)
    }

    static func bugReportMailURL() -> URL? {
        let subject = "Bug Report for Clipmighty"
        let body = defaultBugBody()
        return mailtoURL(subject: subject, body: body)
    }

    static func exportSupportLog(
        to directory: URL = FileManager.default.temporaryDirectory,
        infoDictionary: [String: Any]? = Bundle.main.infoDictionary,
        additionalLines: [String] = []
    ) throws -> URL {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let timestamp = DateFormatter.supportFileNameTimestamp.string(from: Date())
        let fileURL = directory.appendingPathComponent("clipmighty-support-\(timestamp).log")

        var lines: [String] = [
            "Clipmighty Support Log",
            "Generated: \(ISO8601DateFormatter().string(from: Date()))",
            versionDescription(infoDictionary: infoDictionary),
            "macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)",
            "",
            "Preferences Snapshot:",
            "enableCloudSync=\(UserDefaults.standard.bool(forKey: "enableCloudSync"))",
            "ignoreConcealedContent=\(UserDefaults.standard.object(forKey: "ignoreConcealedContent") as? Bool ?? true)",
            "retentionDuration=\(UserDefaults.standard.integer(forKey: "retentionDuration"))",
            ""
        ]

        lines.append(contentsOf: additionalLines)

        let content = lines.joined(separator: "\n")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    static func mailAppleScript(
        to recipient: String,
        subject: String,
        body: String,
        attachmentFileURL: URL?
    ) -> String {
        let escapedRecipient = appleScriptEscaped(recipient)
        let escapedSubject = appleScriptEscaped(subject)
        let escapedBody = appleScriptEscaped(body)

        var script = """
        tell application \"Mail\"
            activate
            set newMessage to make new outgoing message with properties {subject:\"\(escapedSubject)\", content:\"\(escapedBody)\", visible:true}
            tell newMessage
                make new to recipient at end of to recipients with properties {address:\"\(escapedRecipient)\"}
        """

        if let attachmentFileURL {
            let escapedPath = appleScriptEscaped(attachmentFileURL.path)
            script += "\n        make new attachment with properties {file name:(POSIX file \"\(escapedPath)\")} at after the last paragraph"
        }

        script += """
            end tell
        end tell
        """

        return script
    }

    @discardableResult
    static func openContactEmail() -> Bool {
        guard let url = contactMailURL() else {
            return false
        }
        return NSWorkspace.shared.open(url)
    }

    @discardableResult
    static func openBugReportEmail(includeLogAttachment: Bool) -> Bool {
        guard includeLogAttachment else {
            guard let url = bugReportMailURL() else {
                return false
            }
            return NSWorkspace.shared.open(url)
        }

        do {
            let attachmentURL = try exportSupportLog()
            let body = defaultBugBody().replacingOccurrences(of: "%0A", with: "\n")
            let script = mailAppleScript(
                to: supportEmail,
                subject: "Bug Report for Clipmighty",
                body: body,
                attachmentFileURL: attachmentURL
            )
            guard let appleScript = NSAppleScript(source: script) else {
                return false
            }

            var error: NSDictionary?
            _ = appleScript.executeAndReturnError(&error)

            if error != nil {
                if let fallbackURL = bugReportMailURL() {
                    return NSWorkspace.shared.open(fallbackURL)
                }
                return false
            }

            return true
        } catch {
            if let fallbackURL = bugReportMailURL() {
                return NSWorkspace.shared.open(fallbackURL)
            }
            return false
        }
    }

    private static func mailtoURL(subject: String, body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }

    private static func defaultBugBody() -> String {
        let lines = [
            "Hi Clipmighty team,",
            "",
            "Please describe the issue:",
            "",
            "Expected behavior:",
            "",
            "Actual behavior:",
            "",
            "---",
            versionDescription(),
            "macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)",
            "Timestamp: \(ISO8601DateFormatter().string(from: Date()))"
        ]

        return lines.joined(separator: "\n")
    }

    private static func appleScriptEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

private extension DateFormatter {
    static let supportFileNameTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}
