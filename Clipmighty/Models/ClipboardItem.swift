import Foundation
import SwiftData
import CryptoKit

@Model
final class ClipboardItem: Identifiable {
    var id: UUID = UUID()

    var content: String = ""
    var timestamp: Date = Date()
    var sourceAppBundleID: String?
    var sourceAppName: String?
    var isPinned: Bool = false
    var contentHash: String?

    // New fields for multiple types support
    var itemTypeRaw: String = ClipboardItemType.text.rawValue

    var itemType: ClipboardItemType {
        get { ClipboardItemType(rawValue: itemTypeRaw) ?? .text }
        set { itemTypeRaw = newValue.rawValue }
    }

    @Attribute(.externalStorage) var imageData: Data?
    var fileURL: URL?
    var securityScopedBookmark: Data?
    @Attribute(.externalStorage) var richTextData: Data? // HTML or RTF
    var format: String? // "rtf", "html"
    var colorData: Data? // Archived NSColor

    init(content: String,
         itemType: ClipboardItemType = .text,
         timestamp: Date = Date(),
         sourceAppBundleID: String? = nil,
         sourceAppName: String? = nil,
         isPinned: Bool = false,
         imageData: Data? = nil,
         fileURL: URL? = nil,
         securityScopedBookmark: Data? = nil,
         richTextData: Data? = nil,
         format: String? = nil,
         colorData: Data? = nil) {

        self.content = content
        self.itemTypeRaw = itemType.rawValue
        self.timestamp = timestamp
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
        self.isPinned = isPinned

        // Compute hash for text deduplication
        if !content.isEmpty {
            let inputData = Data(content.utf8)
            let hashed = SHA256.hash(data: inputData)
            self.contentHash = hashed.compactMap { String(format: "%02x", $0) }.joined()
        }

        self.imageData = imageData
        self.fileURL = fileURL
        self.securityScopedBookmark = securityScopedBookmark
        self.richTextData = richTextData
        self.format = format
        self.colorData = colorData
    }
}

enum ClipboardItemType: String, Codable {
    case text
    case file
    case image
    case color
    case link
    case webContent // For HTML/Rich Text that isn't just a link
}
