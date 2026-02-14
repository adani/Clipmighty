//
//  SettingsView.swift
//  Clipmighty
//
//  Main settings view using native macOS Settings scene with toolbar tabs.
//  Individual tab views are in Features/Settings/
//

import AppKit
import SwiftData
import SwiftUI

struct SettingsView: View {
    @AppStorage("retentionDuration") private var retentionDuration: Int = 604800 // Default 7 days
    @AppStorage("enableCloudSync") private var enableCloudSync: Bool = false
    @AppStorage(SettingsTab.userDefaultsKey) private var selectedTabRawValue: String =
        SettingsTab.general.rawValue
    @Environment(ClipboardMonitor.self) private var monitor

    var body: some View {
        TabView(selection: selectedTabBinding) {
            GeneralSettingsView(retentionDuration: $retentionDuration)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(SettingsTab.general)

            RulesSettingsView(monitor: monitor, retentionDuration: $retentionDuration)
                .tabItem {
                    Label("Rules", systemImage: "hand.raised.fill")
                }
                .tag(SettingsTab.rules)

            SyncSettingsView(enableCloudSync: $enableCloudSync)
                .tabItem {
                    Label("Sync", systemImage: "icloud.fill")
                }
                .tag(SettingsTab.sync)

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(SettingsTab.about)
        }
        .frame(
            minWidth: 480,
            idealWidth: 520,
            maxWidth: 700,
            minHeight: 380,
            idealHeight: 420,
            maxHeight: 600
        )
    }

    private var selectedTabBinding: Binding<SettingsTab> {
        Binding(
            get: {
                SettingsTab(rawValue: selectedTabRawValue) ?? .general
            },
            set: { newValue in
                selectedTabRawValue = newValue.rawValue
            }
        )
    }
}
