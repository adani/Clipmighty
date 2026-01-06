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
            googleDriveSection
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .alert("Restart Required", isPresented: $showRestartAlert) {
            Button("Restart Now", role: .destructive) {
                restartApp()
            }
            Button("Later", role: .cancel) {}
        } message: {
            Text("Clipmighty needs to restart to apply changes to sync settings.")
        }
    }

    // MARK: - iCloud Section

    private var iCloudSection: some View {
        Section {
            Toggle(isOn: $enableCloudSync) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sync with iCloud")
                    if enableCloudSync {
                        Text(
                            "Clipboard history syncs across your devices signed into the same iCloud account."
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Enable to sync clipboard history across your devices.")
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
            Text("iCloud")
        }
    }

    // MARK: - Google Drive Section

    private var googleDriveSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Google Drive")
                    Text("Coming soon")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Connect…") {
                    // Placeholder for OAuth flow
                }
                .disabled(true)
                .controlSize(.regular)
            }
        } header: {
            Text("Other Services")
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
