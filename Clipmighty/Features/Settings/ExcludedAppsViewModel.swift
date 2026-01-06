//
//  ExcludedAppsViewModel.swift
//  Clipmighty
//
//  Created on 2026-01-07.
//

import Foundation
import SwiftUI
import AppKit

/// View model for managing excluded apps
@MainActor
@Observable
class ExcludedAppsViewModel {
    
    // MARK: - Published Properties
    
    private(set) var excludedApps: [ExcludedApp] = []
    var installedApps: [AppDiscoveryService.InstalledApp] = []
    var isLoadingApps = false
    var showAppPicker = false
    var showManualEntry = false
    var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let appDiscovery = AppDiscoveryService()
    private let userDefaultsKey = "excludedApps"
    private weak var monitor: ClipboardMonitor?
    
    // MARK: - Initialization
    
    init(monitor: ClipboardMonitor? = nil) {
        self.monitor = monitor
        loadFromUserDefaults()
    }
    
    // MARK: - Public Methods
    
    /// Load all installed applications
    func loadInstalledApps() async {
        isLoadingApps = true
        errorMessage = nil
        
        do {
            installedApps = await appDiscovery.getInstalledApplications()
            isLoadingApps = false
        } catch {
            errorMessage = "Failed to load applications: \(error.localizedDescription)"
            isLoadingApps = false
        }
    }
    
    /// Add an app to the excluded list
    func addApp(bundleID: String, name: String, icon: NSImage?, isManual: Bool) {
        // Check for duplicates
        guard !excludedApps.contains(where: { $0.bundleID == bundleID }) else {
            errorMessage = "App is already excluded"
            return
        }
        
        let app = ExcludedApp(bundleID: bundleID, name: name, icon: icon, isManualEntry: isManual)
        excludedApps.append(app)
        excludedApps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        
        saveToUserDefaults()
        updateMonitorDenylist()
        
        errorMessage = nil
    }
    
    /// Add multiple apps at once
    func addApps(_ apps: [AppDiscoveryService.InstalledApp]) {
        for app in apps where !excludedApps.contains(where: { $0.bundleID == app.bundleID }) {
            let excludedApp = ExcludedApp(
                bundleID: app.bundleID,
                name: app.name,
                icon: app.icon,
                isManualEntry: false
            )
            excludedApps.append(excludedApp)
        }
        
        excludedApps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        saveToUserDefaults()
        updateMonitorDenylist()
        
        errorMessage = nil
    }
    
    /// Remove apps at specified indices
    func removeApps(at offsets: IndexSet) {
        excludedApps.remove(atOffsets: offsets)
        saveToUserDefaults()
        updateMonitorDenylist()
    }
    
    /// Remove a specific app by ID
    func removeApp(id: UUID) {
        excludedApps.removeAll { $0.id == id }
        saveToUserDefaults()
        updateMonitorDenylist()
    }
    
    /// Validate and add a manually entered bundle ID
    func validateAndAddManualBundleID(_ bundleID: String) -> Bool {
        // Trim whitespace
        let trimmedID = bundleID.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate format
        guard appDiscovery.validateBundleID(trimmedID) else {
            errorMessage = "Invalid bundle ID format. Expected format: com.example.app"
            return false
        }
        
        // Check for duplicates
        guard !excludedApps.contains(where: { $0.bundleID == trimmedID }) else {
            errorMessage = "App is already excluded"
            return false
        }
        
        // Try to get app info
        let appInfo = appDiscovery.getAppInfo(bundleID: trimmedID)
        let name = appInfo?.name ?? trimmedID
        let icon = appInfo?.icon
        
        addApp(bundleID: trimmedID, name: name, icon: icon, isManual: true)
        
        return true
    }
    
    /// Set the clipboard monitor for syncing
    func setMonitor(_ monitor: ClipboardMonitor) {
        self.monitor = monitor
        updateMonitorDenylist()
    }
    
    // MARK: - Private Methods
    
    /// Load excluded apps from UserDefaults
    private func loadFromUserDefaults() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            // Add default exclusions if no data exists
            addDefaultExclusions()
            return
        }
        
        do {
            let decoder = JSONDecoder()
            excludedApps = try decoder.decode([ExcludedApp].self, from: data)
            updateMonitorDenylist()
        } catch {
            print("Failed to load excluded apps: \(error)")
            addDefaultExclusions()
        }
    }
    
    /// Save excluded apps to UserDefaults
    private func saveToUserDefaults() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(excludedApps)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save excluded apps: \(error)")
            errorMessage = "Failed to save changes"
        }
    }
    
    /// Update the clipboard monitor's denylist
    private func updateMonitorDenylist() {
        guard let monitor = monitor else { return }
        monitor.denylistedBundleIDs = Set(excludedApps.map(\.bundleID))
    }
    
    /// Add default apps to exclude
    private func addDefaultExclusions() {
        // Add Keychain Access by default
        let keychainBundleID = "com.apple.keychainaccess"
        if let info = appDiscovery.getAppInfo(bundleID: keychainBundleID) {
            addApp(bundleID: keychainBundleID, name: info.name, icon: info.icon, isManual: false)
        } else {
            addApp(bundleID: keychainBundleID, name: "Keychain Access", icon: nil, isManual: false)
        }
    }
}
