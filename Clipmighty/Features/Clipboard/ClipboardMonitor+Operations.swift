//
//  ClipboardMonitor+Operations.swift
//  Clipmighty
//
//  Clipboard operations: Reading from and writing to NSPasteboard.
//

import AppKit
import SwiftUI

extension ClipboardMonitor {

    // MARK: - Clipboard Operations

    // Explicitly copy to clipboard and update state so we don't "detect" it as new
    func copyToClipboard(_ item: ClipboardItem) {
        pasteboard.clearContents()

        // Restore based on type
        switch item.itemType {
        case .file:
            copyFileToClipboard(item)

        case .image:
            if let data = item.imageData, let image = NSImage(data: data) {
                pasteboard.writeObjects([image])
            }

        case .color:
            if let data = item.colorData,
                let color = try? NSKeyedUnarchiver.unarchivedObject(
                    ofClass: NSColor.self, from: data) {
                pasteboard.writeObjects([color])
            } else {
                // Fallback to hex string
                pasteboard.setString(item.content, forType: .string)
            }

        case .webContent:
            copyWebContentToClipboard(item)

        default:
            // Text and Links
            pasteboard.setString(item.content, forType: .string)
        }

        // Update lastChangeCount to the current count immediately
        // allowing us to ignore the change we just caused.
        // NOTE: writeObjects implies changeCount increment.
        self.updateLastChangeCount()
        self.currentContent = item.content

        if UserDefaults.standard.bool(forKey: "reorderCopiedItemsToTop") {
            onHistoryItemCopied?(item.id)
        }
    }

    private func copyFileToClipboard(_ item: ClipboardItem) {
        if let bookmark = item.securityScopedBookmark {
            // Try to resolve bookmark to get fresh URL
            var isStale = false
            do {
                let url = try URL(
                    resolvingBookmarkData: bookmark,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale)

                if isStale {
                    print(
                        "[ClipboardMonitor] Bookmark is stale, but we resolved it to: \(url.path)")
                }

                // Access security scoped resource
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }

                // Write file URL in proper format for Finder
                // Finder expects both the URL reference AND the file-url type
                if let urlData = url.absoluteString.data(using: .utf8) {
                    pasteboard.setData(urlData, forType: .fileURL)
                }
                // Also write as NSURL for compatibility
                pasteboard.writeObjects([url as NSURL])

            } catch {
                print("[ClipboardMonitor] Failed to resolve bookmark: \(error)")
                // Fallback to stored URL if available
                if let url = item.fileURL {
                    if let urlData = url.absoluteString.data(using: .utf8) {
                        pasteboard.setData(urlData, forType: .fileURL)
                    }
                    pasteboard.writeObjects([url as NSURL])
                } else {
                    pasteboard.setString(item.content, forType: .string)
                }
            }
        } else if let url = item.fileURL {
            if let urlData = url.absoluteString.data(using: .utf8) {
                pasteboard.setData(urlData, forType: .fileURL)
            }
            pasteboard.writeObjects([url as NSURL])
        }
    }

    private func copyWebContentToClipboard(_ item: ClipboardItem) {
        // Restore Rich Text / HTML
        if let data = item.richTextData {
            if item.format == "html" {
                pasteboard.setData(data, forType: .html)
                pasteboard.setString(item.content, forType: .string)  // Also set plain text
            } else if item.format == "rtf" {
                pasteboard.setData(data, forType: .rtf)
                pasteboard.setString(item.content, forType: .string)
            }
        } else {
            pasteboard.setString(item.content, forType: .string)
        }
    }

    // Support legacy string method for now if needed (or remove if fully migrated)
    func copyToClipboard(_ content: String) {
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        self.updateLastChangeCount()
        self.currentContent = content
    }

    // MARK: - Item Creation Helpers

    func createBestItem(
        from types: [NSPasteboard.PasteboardType], bundleID: String?, appName: String?
    ) -> ClipboardItem? {
        // Priority: File -> Color -> Image -> Rich/HTML -> Text
        if types.contains(.fileURL) {
            if let item = createFileItem(bundleID: bundleID, appName: appName) { return item }
        }

        if types.contains(.color) {
            if let item = createColorItem(bundleID: bundleID, appName: appName) { return item }
        }

        if types.contains(.png) || types.contains(.tiff) || types.contains(.jpeg) {
            if let item = createImageItem(bundleID: bundleID, appName: appName) { return item }
        }

        if types.contains(.html) || types.contains(.rtf) {
            if let item = createWebContentItem(bundleID: bundleID, appName: appName) { return item }
        }

        return createTextItem(bundleID: bundleID, appName: appName)
    }

    func createFileItem(bundleID: String?, appName: String?) -> ClipboardItem? {
        guard
            let url = pasteboard.readObjects(forClasses: [NSURL.self], options: nil)?.first as? URL
        else {
            return nil
        }

        // Create bookmark
        var bookmarkData: Data?
        do {
            // Create access to the file to generate bookmark
            _ = url.startAccessingSecurityScopedResource()
            bookmarkData = try url.bookmarkData(
                options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            url.stopAccessingSecurityScopedResource()
        } catch {
            print("[ClipboardMonitor] Failed to create bookmark for \(url): \(error)")
        }

        return ClipboardItem(
            content: url.lastPathComponent,
            itemType: .file,
            sourceAppBundleID: bundleID,
            sourceAppName: appName,
            fileURL: url,
            securityScopedBookmark: bookmarkData
        )
    }

    func createColorItem(bundleID: String?, appName: String?) -> ClipboardItem? {
        guard
            let color = pasteboard.readObjects(forClasses: [NSColor.self], options: nil)?.first
                as? NSColor
        else {
            return nil
        }

        // Archive color
        let colorData = try? NSKeyedArchiver.archivedData(
            withRootObject: color, requiringSecureCoding: false)

        // Hex string
        let hex = hexString(from: color)

        return ClipboardItem(
            content: hex,
            itemType: .color,
            sourceAppBundleID: bundleID,
            sourceAppName: appName,
            colorData: colorData
        )
    }

    func createImageItem(bundleID: String?, appName: String?) -> ClipboardItem? {
        guard
            let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first
                as? NSImage,
            let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            return nil
        }

        // Downscale if too huge? For now store as is but maybe limit size?
        // Let's store a generic "Image" text
        let sizeStr = "\(Int(image.size.width))x\(Int(image.size.height))"

        return ClipboardItem(
            content: "Image \(sizeStr)",
            itemType: .image,
            sourceAppBundleID: bundleID,
            sourceAppName: appName,
            imageData: pngData
        )
    }

    func createWebContentItem(bundleID: String?, appName: String?) -> ClipboardItem? {
        // Try to get plain text first for content preview
        let plainText = pasteboard.string(forType: .string) ?? "Rich Text Content"

        var rtfData: Data?
        var format: String?

        if let data = pasteboard.data(forType: .html) {
            rtfData = data
            format = "html"
        } else if let data = pasteboard.data(forType: .rtf) {
            rtfData = data
            format = "rtf"
        }

        return ClipboardItem(
            content: plainText,
            itemType: .webContent,
            sourceAppBundleID: bundleID,
            sourceAppName: appName,
            richTextData: rtfData,
            format: format
        )
    }

    func createTextItem(bundleID: String?, appName: String?) -> ClipboardItem? {
        guard let content = pasteboard.string(forType: .string), !content.isEmpty else {
            return nil
        }

        // Check if link
        let type: ClipboardItemType = isValidUrl(content) ? .link : .text

        return ClipboardItem(
            content: content,
            itemType: type,
            sourceAppBundleID: bundleID,
            sourceAppName: appName
        )
    }

    // MARK: - Helpers

    private func hexString(from color: NSColor) -> String {
        guard let rgbColor = color.usingColorSpace(.sRGB) else { return "#FFFFFF" }
        let red = Int(round(rgbColor.redComponent * 0xFF))
        let green = Int(round(rgbColor.greenComponent * 0xFF))
        let blue = Int(round(rgbColor.blueComponent * 0xFF))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    private func isValidUrl(_ string: String) -> Bool {
        // Simple check
        if let url = URL(string: string), url.scheme != nil, url.host != nil {
            return true
        }
        return false
    }
}
