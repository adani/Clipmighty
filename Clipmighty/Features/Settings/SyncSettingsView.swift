//
//  SyncSettingsView.swift
//  Clipmighty
//
//  Sync settings tab for iCloud and Google Drive integration.
//

import AppKit
import SwiftUI

struct SyncSettingsView: View {
    @Binding var enableCloudSync: Bool
    @State private var showRestartAlert = false

    var body: some View {
        Form {
            iCloudSection
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .alert(L10n.syncRestartTitle.text, isPresented: $showRestartAlert) {
            Button(L10n.syncRestartNow.text, role: .destructive) {
                restartApp()
            }
            Button(L10n.syncLater.text, role: .cancel) {}
        } message: {
            Text(L10n.syncRestartMessage.text)
        }
    }

    // MARK: - iCloud Section

    private var iCloudSection: some View {
        Section {
            Toggle(isOn: $enableCloudSync) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.syncWithICloud.text)
                    if enableCloudSync {
                        Text(L10n.syncICloudEnabledDescription.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(L10n.syncICloudDisabledDescription.text)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .onChange(of: enableCloudSync) { _, _ in
                showRestartAlert = true
            }
        } header: {
            Text(L10n.syncICloudSection.text)
        }
    }

    // MARK: - Actions

    private func restartApp() {
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()

        AppDelegate.isForceQuit = true
        NSApplication.shared.terminate(nil)
    }
}
