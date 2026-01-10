//
//  OnboardingViewModel.swift
//  Clipmighty
//
//  Created on 2026-01-09.
//

import Foundation
import SwiftUI
import AppKit

/// Represents the steps in the onboarding flow
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case permissions = 1
    case excludedApps = 2
    case tutorial = 3
}

/// View model for managing onboarding state
@MainActor
@Observable
class OnboardingViewModel {

    // MARK: - Published Properties

    var currentStep: OnboardingStep = .welcome
    var hasAccessibilityPermission = false
    var excludedApps: [ExcludedApp] = []
    var tutorialCopiedText: String?
    var tutorialPastedText: String = ""
    var isTutorialComplete = false

    // For the rotating features animation
    var currentFeatureIndex = 0
    let features = [
        "📋 Instant clipboard history",
        "🔍 Powerful search",
        "⌨️ Quick keyboard shortcuts",
        "🔒 Privacy-focused design",
        "☁️ iCloud sync support",
        "🚫 App exclusion rules"
    ]

    // For app picker
    var installedApps: [AppDiscoveryService.InstalledApp] = []
    var isLoadingApps = false

    // Default apps to exclude
    private let defaultExcludedBundleIDs = [
        ("com.apple.keychainaccess", "Keychain Access"),
        ("com.apple.Passwords", "Passwords"),
        ("com.apple.Wallet", "Wallet"),
        ("com.1password.1password", "1Password"),
        ("com.agilebits.onepassword7", "1Password 7"),
        ("com.bitwarden.desktop", "Bitwarden"),
        ("com.dashlane.Dashlane", "Dashlane"),
        ("com.lastpass.LastPass", "LastPass")
    ]

    // MARK: - Private Properties

    private let appDiscovery = AppDiscoveryService()
    private let userDefaultsKey = "excludedApps"
    private var featureTimer: Timer?

    // MARK: - Initialization

    init() {
        checkAccessibilityPermission()
        loadDefaultExcludedApps()
        startFeatureRotation()
    }

    /// Stop the feature rotation timer
    func stopFeatureRotation() {
        featureTimer?.invalidate()
        featureTimer = nil
    }

    // MARK: - Public Methods

    /// Check if onboarding has been completed before
    static var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    /// Mark onboarding as complete
    func completeOnboarding() {
        saveExcludedApps()
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    /// Move to the next step
    func nextStep() {
        if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = next
            }
        }
    }

    /// Move to the previous step
    func previousStep() {
        if let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = prev
            }
        }
    }

    /// Check if we can proceed to the next step
    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .permissions:
            return hasAccessibilityPermission
        case .excludedApps:
            return true
        case .tutorial:
            return isTutorialComplete
        }
    }

    /// Check accessibility permission status
    func checkAccessibilityPermission() {
        hasAccessibilityPermission = AXIsProcessTrusted()
    }

    /// Request accessibility permission
    func requestAccessibilityPermission() {
        // Trigger the system prompt
        PasteHelper.requestPermission()

        // Open System Settings to the Accessibility pane
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }

        // Start a timer to check for permission grant
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor in
                self?.checkAccessibilityPermission()
                if self?.hasAccessibilityPermission == true {
                    timer.invalidate()
                }
            }
        }
    }

    /// Toggle an excluded app
    func toggleExcludedApp(_ app: ExcludedApp) {
        if let index = excludedApps.firstIndex(where: { $0.id == app.id }) {
            excludedApps.remove(at: index)
        } else {
            excludedApps.append(app)
        }
    }

    /// Check if an app is excluded
    func isAppExcluded(_ bundleID: String) -> Bool {
        excludedApps.contains { $0.bundleID == bundleID }
    }

    /// Add a new app by bundle ID
    func addApp(bundleID: String) -> Bool {
        let trimmedID = bundleID.trimmingCharacters(in: .whitespacesAndNewlines)

        // Basic validation
        guard !trimmedID.isEmpty,
              trimmedID.contains("."),
              !excludedApps.contains(where: { $0.bundleID == trimmedID }) else {
            return false
        }

        // Try to get app info
        let appInfo = appDiscovery.getAppInfo(bundleID: trimmedID)
        let name = appInfo?.name ?? trimmedID
        let icon = appInfo?.icon

        let app = ExcludedApp(bundleID: trimmedID, name: name, icon: icon, isManualEntry: true)
        excludedApps.append(app)
        excludedApps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        return true
    }

    /// Check if tutorial text was pasted correctly
    func checkTutorialPaste() {
        // User requested to allow continuing after pasting ANY text, not just the specific one.
        // We relax the check to just ensure the text is not empty.
        if !tutorialPastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            withAnimation {
                isTutorialComplete = true
            }
        }
    }

    /// Load all installed applications for app picker
    func loadInstalledApps() async {
        isLoadingApps = true
        installedApps = await appDiscovery.getInstalledApplications()
        isLoadingApps = false
    }

    /// Add multiple apps at once from app picker
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
    }

    // MARK: - Private Methods

    private func startFeatureRotation() {
        featureTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.currentFeatureIndex = (self.currentFeatureIndex + 1) % self.features.count
                }
            }
        }
    }

    private func loadDefaultExcludedApps() {
        // Always add Keychain Access
        let keychainID = "com.apple.keychainaccess"
        if let info = appDiscovery.getAppInfo(bundleID: keychainID) {
            excludedApps.append(ExcludedApp(bundleID: keychainID, name: info.name, icon: info.icon))
        } else {
            excludedApps.append(ExcludedApp(bundleID: keychainID, name: "Keychain Access"))
        }

        // Add other apps if they're installed
        for (bundleID, fallbackName) in defaultExcludedBundleIDs where bundleID != keychainID {
            if let info = appDiscovery.getAppInfo(bundleID: bundleID) {
                excludedApps.append(ExcludedApp(bundleID: bundleID, name: info.name, icon: info.icon))
            }
            // Only add if installed - don't add placeholder entries for non-installed apps
        }

        excludedApps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func saveExcludedApps() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(excludedApps)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("[Onboarding] Failed to save excluded apps: \(error)")
        }
    }
}
