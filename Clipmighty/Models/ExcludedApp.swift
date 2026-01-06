//
//  ExcludedApp.swift
//  Clipmighty
//
//  Created on 2026-01-07.
//

import Foundation
import AppKit

/// Represents an application that should be excluded from clipboard monitoring
struct ExcludedApp: Identifiable, Codable, Hashable {
    let id: UUID
    let bundleID: String
    let name: String
    let iconData: Data?
    let addedDate: Date
    let isManualEntry: Bool
    
    init(bundleID: String, name: String, icon: NSImage? = nil, isManualEntry: Bool = false) {
        self.id = UUID()
        self.bundleID = bundleID
        self.name = name
        self.iconData = icon?.tiffRepresentation
        self.addedDate = Date()
        self.isManualEntry = isManualEntry
    }
    
    /// Get the app icon as NSImage
    var icon: NSImage? {
        guard let iconData = iconData else { return nil }
        return NSImage(data: iconData)
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ExcludedApp, rhs: ExcludedApp) -> Bool {
        lhs.id == rhs.id
    }
}
