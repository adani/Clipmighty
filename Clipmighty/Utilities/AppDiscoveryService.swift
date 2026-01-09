//
//  AppDiscoveryService.swift
//  Clipmighty
//
//  Created on 2026-01-07.
//

import Foundation
import AppKit

/// Service for discovering and managing installed macOS applications
@MainActor
class AppDiscoveryService {

    // MARK: - Data Structures

    /// Represents an installed application
    struct InstalledApp: Identifiable, Hashable {
        let id = UUID()
        let bundleID: String
        let name: String
        let path: URL
        var icon: NSImage?

        func hash(into hasher: inout Hasher) {
            hasher.combine(bundleID)
        }

        static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
            lhs.bundleID == rhs.bundleID
        }
    }

    /// Detailed information about an application
    struct AppInfo {
        let bundleID: String
        let name: String
        let icon: NSImage?
        let path: URL
    }

    // MARK: - Public Methods

    /// Get all installed applications on the system
    func getInstalledApplications() async -> [InstalledApp] {
        var apps: [InstalledApp] = []
        let fileManager = FileManager.default

        // Directories to scan for applications
        let appDirectories = [
            "/Applications",
            "/System/Applications",
            URL.homeDirectory.appendingPathComponent("Applications").path
        ]

        for directory in appDirectories {
            guard let appURLs = try? fileManager.contentsOfDirectory(
                at: URL(fileURLWithPath: directory),
                includingPropertiesForKeys: [.isApplicationKey],
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for appURL in appURLs where appURL.pathExtension == "app" {
                if let installedApp = await loadAppInfo(from: appURL) {
                    // Avoid duplicates
                    if !apps.contains(where: { $0.bundleID == installedApp.bundleID }) {
                        apps.append(installedApp)
                    }
                }
            }
        }

        // Sort alphabetically by name
        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Get information about an app from its bundle ID
    func getAppInfo(bundleID: String) -> AppInfo? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }

        guard let bundle = Bundle(url: appURL) else {
            return nil
        }

        let name = getAppName(from: bundle) ?? bundleID
        let icon = getAppIcon(from: appURL)

        return AppInfo(bundleID: bundleID, name: name, icon: icon, path: appURL)
    }

    /// Get an app's icon from its bundle ID
    func getAppIcon(bundleID: String) -> NSImage? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        return getAppIcon(from: appURL)
    }

    /// Get an app's name from its bundle ID
    func getAppName(bundleID: String) -> String? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
              let bundle = Bundle(url: appURL) else {
            return nil
        }
        return getAppName(from: bundle)
    }

    /// Validate a bundle ID format
    func validateBundleID(_ bundleID: String) -> Bool {
        // Bundle ID should follow reverse DNS notation: com.example.app
        let pattern = "^[a-zA-Z0-9]+(\\.[a-zA-Z0-9-]+)+$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: bundleID.utf16.count)
        return regex?.firstMatch(in: bundleID, range: range) != nil
    }

    // MARK: - Private Helper Methods

    /// Load app info from an app bundle URL
    private func loadAppInfo(from appURL: URL) async -> InstalledApp? {
        guard let bundle = Bundle(url: appURL),
              let bundleID = bundle.bundleIdentifier else {
            return nil
        }

        let name = getAppName(from: bundle) ?? appURL.deletingPathExtension().lastPathComponent
        let icon = getAppIcon(from: appURL)

        return InstalledApp(
            bundleID: bundleID,
            name: name,
            path: appURL,
            icon: icon
        )
    }

    /// Get app name from bundle
    private func getAppName(from bundle: Bundle) -> String? {
        // Try localized name first
        if let localizedName = bundle.localizedInfoDictionary?["CFBundleName"] as? String {
            return localizedName
        }

        // Try display name
        if let displayName = bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String {
            return displayName
        }

        // Fall back to regular info dictionary
        if let name = bundle.infoDictionary?["CFBundleName"] as? String {
            return name
        }

        if let displayName = bundle.infoDictionary?["CFBundleDisplayName"] as? String {
            return displayName
        }

        return nil
    }

    /// Get app icon from app URL
    private func getAppIcon(from appURL: URL) -> NSImage? {
        let icon = NSWorkspace.shared.icon(forFile: appURL.path)

        // Resize to a reasonable size for display (32x32 points, which is 64x64 pixels on retina)
        let targetSize = NSSize(width: 32, height: 32)
        let resizedIcon = NSImage(size: targetSize)
        resizedIcon.lockFocus()
        icon.draw(in: NSRect(origin: .zero, size: targetSize),
                  from: NSRect(origin: .zero, size: icon.size),
                  operation: .copy,
                  fraction: 1.0)
        resizedIcon.unlockFocus()

        return resizedIcon
    }
}
