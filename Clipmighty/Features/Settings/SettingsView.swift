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
    @Environment(ClipboardMonitor.self) private var monitor

    private enum Tabs: Hashable {
        case general
        case rules
        case sync
    }

    var body: some View {
        TabView {
            GeneralSettingsView(retentionDuration: $retentionDuration)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(Tabs.general)

            RulesSettingsView(monitor: monitor, retentionDuration: $retentionDuration)
                .tabItem {
                    Label("Rules", systemImage: "hand.raised.fill")
                }
                .tag(Tabs.rules)

            SyncSettingsView(enableCloudSync: $enableCloudSync)
                .tabItem {
                    Label("Sync", systemImage: "icloud.fill")
                }
                .tag(Tabs.sync)
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
}
