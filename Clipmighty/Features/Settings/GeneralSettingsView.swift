//
//  GeneralSettingsView.swift
//  Clipmighty
//
//  General settings tab including history retention and permissions.
//

import AppKit
import Carbon
import SwiftData
import SwiftUI

struct GeneralSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var retentionDuration: Int // seconds
    @State private var showingClearConfirmation = false
    @State private var isAccessibilityTrusted: Bool = PasteHelper.canPaste()

    // UI state for custom duration
    @State private var customMinutes: Int = 30
    @State private var customUnit: TimeUnit = .minutes
    @State private var selectedOption: RetentionOption = .days7 // Default fallback
    
    // Keyboard shortcut configuration
    @State private var shortcutKeyCode: Int = KeyCode.vKey
    @State private var shortcutModifiers: Int = cmdKey | shiftKey

    enum TimeUnit: String, CaseIterable, Identifiable {
        case minutes
        case hours
        case days

        var id: String { rawValue }

        var secondsMultiplier: Int {
            switch self {
            case .minutes: return 60
            case .hours: return 3600
            case .days: return 86400
            }
        }
    }

    enum RetentionOption: Hashable {
        case minutes30
        case hours8
        case hours24
        case days7
        case forever
        case custom

        var label: String {
            switch self {
            case .minutes30: return "30 Minutes"
            case .hours8: return "8 Hours"
            case .hours24: return "24 Hours"
            case .days7: return "7 Days"
            case .forever: return "Forever"
            case .custom: return "Custom..."
            }
        }

        // Helper to match seconds to an option
        static func from(seconds: Int) -> RetentionOption {
            switch seconds {
            case 0: return .forever
            case 1800: return .minutes30
            case 28800: return .hours8
            case 86400: return .hours24
            case 604800: return .days7
            default: return .custom
            }
        }
    }

    var body: some View {
        Form {
            if !isAccessibilityTrusted {
                permissionsSection
            }
            
            shortcutSection

            historySection
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .onAppear {
            checkPermission()
            initializeState()
            loadShortcutPreferences()
        }
        .onChange(of: retentionDuration) { _, newValue in
             // Sync external changes back to local state if needed
             // but mostly we drive from local state -> binding
             let newOption = RetentionOption.from(seconds: newValue)
             if newOption != .custom && newOption != selectedOption {
                 selectedOption = newOption
             }
         }
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        ) { _ in
            checkPermission()
        }
    }

    private func initializeState() {
        selectedOption = RetentionOption.from(seconds: retentionDuration)
        if selectedOption == .custom {
            // Determine best unit for current seconds
            if retentionDuration % 86400 == 0 {
                customUnit = .days
                customMinutes = retentionDuration / 86400
            } else if retentionDuration % 3600 == 0 {
                customUnit = .hours
                customMinutes = retentionDuration / 3600
            } else {
                customUnit = .minutes
                customMinutes = retentionDuration / 60
            }
        }
    }

    private func updateRetention() {
        switch selectedOption {
        case .minutes30: retentionDuration = 1800
        case .hours8: retentionDuration = 28800
        case .hours24: retentionDuration = 86400
        case .days7: retentionDuration = 604800
        case .forever: retentionDuration = 0
        case .custom:
            retentionDuration = customMinutes * customUnit.secondsMultiplier
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
                    modifierFlags: $shortcutModifiers
                )
            }
        } header: {
            Text("Keyboard Shortcut")
        } footer: {
            Text("Press a keyboard shortcut to activate the paste overlay. The shortcut must include at least one modifier key (⌘, ⇧, ⌥, or ⌃).")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Permissions Section

    private var permissionsSection: some View {
        Section {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Accessibility Access Required")
                        .font(.headline)

                    Text(
                        "To paste items directly into apps, Clipmighty needs accessibility permission."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                    Button("Open System Settings…") {
                        PasteHelper.requestPermission()
                        openSystemSettings()
                    }
                    .controlSize(.regular)
                    .padding(.top, 2)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        Section {
            Picker("Keep history:", selection: $selectedOption) {
                Text(RetentionOption.minutes30.label).tag(RetentionOption.minutes30)
                Text(RetentionOption.hours8.label).tag(RetentionOption.hours8)
                Text(RetentionOption.hours24.label).tag(RetentionOption.hours24)
                Text(RetentionOption.days7.label).tag(RetentionOption.days7)
                Divider()
                Text(RetentionOption.forever.label).tag(RetentionOption.forever)
                Divider()
                Text(RetentionOption.custom.label).tag(RetentionOption.custom)
            }
            .pickerStyle(.menu)
            .onChange(of: selectedOption) { _, _ in updateRetention() }

            if selectedOption == .custom {
                LabeledContent("Duration:") {
                    HStack(spacing: 8) {
                        TextField("", value: $customMinutes, format: .number)
                            .labelsHidden()
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)

                        Picker("", selection: $customUnit) {
                            Text("Minutes").tag(TimeUnit.minutes)
                            Text("Hours").tag(TimeUnit.hours)
                            Text("Days").tag(TimeUnit.days)
                        }
                        .labelsHidden()
                        .fixedSize()
                        .frame(minWidth: 100)
                    }
                }
                .onChange(of: customMinutes) { _, _ in updateRetention() }
                .onChange(of: customUnit) { _, _ in updateRetention() }
            }
        } footer: {
            HStack {
                Spacer()
                Button("Clear All History…", role: .destructive) {
                    showingClearConfirmation = true
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
                .controlSize(.small)
            }
            .padding(.top, 8)
        }
        .confirmationDialog(
            "Clear Clipboard History?",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This will permanently delete all clipboard history. This action cannot be undone.")
        }
    }

    // MARK: - Actions
    
    private func loadShortcutPreferences() {
        // Load saved shortcut or use default (Cmd+Shift+V)
        if let savedKeyCode = UserDefaults.standard.object(forKey: "overlayShortcutKeyCode") as? Int {
            shortcutKeyCode = savedKeyCode
        }
        if let savedModifiers = UserDefaults.standard.object(forKey: "overlayShortcutModifiers") as? Int {
            shortcutModifiers = savedModifiers
        }
    }

    private func checkPermission() {
        isAccessibilityTrusted = PasteHelper.canPaste()
    }

    private func openSystemSettings() {
        if let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func clearHistory() {
        do {
            try modelContext.delete(model: ClipboardItem.self)
        } catch {
            print("Failed to clear history: \(error)")
        }
    }
}
