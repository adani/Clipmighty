//
//  GeneralSettingsView.swift
//  Clipmighty
//
//  General settings tab for startup, shortcuts, and permissions.
//

import AppKit
import Carbon
import SwiftUI

struct GeneralSettingsView: View {
    @Binding var retentionDuration: Int // seconds
    @State private var isAccessibilityTrusted: Bool = PasteHelper.canPaste()
    @AppStorage("reorderCopiedItemsToTop") private var reorderCopiedItemsToTop: Bool = false

    // Keyboard shortcut configuration
    @State private var shortcutKeyCode: Int = KeyCode.vKey
    @State private var shortcutModifiers: Int = controlKey
    @State private var pinShortcutKeyCode: Int = OverlayPinShortcut.defaultKeyCode
    @State private var pinShortcutModifiers: Int = OverlayPinShortcut.defaultModifiers
    @State private var timer: Timer?

    var body: some View {
        Form {
            startupSection

            historyBehaviorSection

            shortcutSection

            permissionsSection
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .padding(.vertical, -8)
        .onAppear {
            checkPermission()
            startPermissionTimer()
            loadShortcutPreferences()
        }
        .onDisappear {
            stopPermissionTimer()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        ) { _ in
            checkPermission()
        }
    }

    // MARK: - Startup Section

    @State private var launchAtLogin: Bool = LaunchAtLoginService.isEnabled

    private var startupSection: some View {
        Section("Startup") {
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    LaunchAtLoginService.isEnabled = newValue
                }
        }
    }

    private var historyBehaviorSection: some View {
        Section("History") {
            Toggle("Move copied history item to top", isOn: $reorderCopiedItemsToTop)
        }
    }

    // MARK: - Shortcut Section

    private var shortcutSection: some View {
        Section {
            HStack(alignment: .center) {
                Text("Paste Overlay:")
                Spacer()
                KeyboardShortcutRecorder(
                    keyCode: $shortcutKeyCode,
                    modifierFlags: $shortcutModifiers,
                    keyCodeDefaultsKey: "overlayShortcutKeyCode",
                    modifiersDefaultsKey: "overlayShortcutModifiers"
                )
            }

            HStack(alignment: .center) {
                Text("Pin/Unpin in Overlay:")
                Spacer()
                KeyboardShortcutRecorder(
                    keyCode: $pinShortcutKeyCode,
                    modifierFlags: $pinShortcutModifiers,
                    keyCodeDefaultsKey: OverlayPinShortcut.keyCodeDefaultsKey,
                    modifiersDefaultsKey: OverlayPinShortcut.modifiersDefaultsKey
                )
            }
        } header: {
            Text("Keyboard Shortcut")
        } footer: {
            Text("Set shortcuts for opening the paste overlay and pinning items in it. " +
                 "The shortcut must include at least one modifier key (⌘, ⇧, ⌥, or ⌃).")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Permissions Section

    private var permissionsSection: some View {
        Section {
            HStack {
                Text("Direct Paste from Overlay")
                Spacer()
                HStack(spacing: 8) {
                    // Status badge
                    Text(isAccessibilityTrusted ? "Enabled" : "Disabled")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(isAccessibilityTrusted ? Color.green : Color.secondary.opacity(0.5))
                        )
                    
                    Button(isAccessibilityTrusted ? "Disable in Accessibility Settings" : "Enable in Accessibility Settings") {
                        openSystemSettings()
                    }
                    .controlSize(.regular)
                }
            }
        } header: {
            Text("Assistive Paste")
        } footer: {
            Text(
                "Allows Clipmighty to insert selected items directly into the active window. " +
                "This reduces the need for repetitive manual keystrokes and complex key chords."
            )
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    // MARK: - Actions

    private func loadShortcutPreferences() {
        // Load saved shortcut or use default (Ctrl+V)
        if let savedKeyCode = UserDefaults.standard.object(forKey: "overlayShortcutKeyCode") as? Int {
            shortcutKeyCode = savedKeyCode
        }
        if let savedModifiers = UserDefaults.standard.object(forKey: "overlayShortcutModifiers") as? Int {
            shortcutModifiers = savedModifiers
        }

        if let savedPinKeyCode = UserDefaults.standard.object(
            forKey: OverlayPinShortcut.keyCodeDefaultsKey
        ) as? Int {
            pinShortcutKeyCode = savedPinKeyCode
        }

        if let savedPinModifiers = UserDefaults.standard.object(
            forKey: OverlayPinShortcut.modifiersDefaultsKey
        ) as? Int {
            pinShortcutModifiers = savedPinModifiers
        }
    }

    private func checkPermission() {
        let isTrusted = PasteHelper.canPaste()
        if isAccessibilityTrusted != isTrusted {
            isAccessibilityTrusted = isTrusted
        }
    }

    // Polling is useful because the user might toggle permission in System Settings
    // without the app necessarily becoming "active" in a way that triggers the notification immediately
    // or if they have the windows side-by-side.
    private func startPermissionTimer() {
        // Stop any existing timer
        timer?.invalidate()

        // precise timer is not needed, 1-2 seconds is enough
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            checkPermission()
        }
    }

    private func stopPermissionTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func openSystemSettings() {
        if let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
