//
//  RulesSettingsView.swift
//  Clipmighty
//
//  Rules settings tab for privacy protection and app exclusions.
//

import SwiftUI

struct RulesSettingsView: View {
    @AppStorage("ignoreConcealedContent") private var ignoreConcealedContent: Bool = true
    @Environment(ClipboardMonitor.self) private var monitor
    @State private var viewModel: ExcludedAppsViewModel
    
    init(monitor: ClipboardMonitor) {
        _viewModel = State(initialValue: ExcludedAppsViewModel(monitor: monitor))
    }

    var body: some View {
        Form {
            privacyProtectionSection
            excludeApplicationsSection
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .sheet(isPresented: $viewModel.showAppPicker) {
            AppPickerSheet(viewModel: $viewModel)
                .task {
                    if viewModel.installedApps.isEmpty {
                        await viewModel.loadInstalledApps()
                    }
                }
                .onAppear {
                    // Ensure app stays active when sheet appears
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .sheet(isPresented: $viewModel.showManualEntry) {
            ManualBundleIDSheet(viewModel: $viewModel)
                .onAppear {
                    // Ensure app stays active when sheet appears
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
    }

    // MARK: - Privacy Protection Section

    private var privacyProtectionSection: some View {
        Section {
            Toggle(isOn: $ignoreConcealedContent) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ignore password manager entries")
                    Text("Detects and skips clipboard content marked as private or auto-generated.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .onChange(of: ignoreConcealedContent) { _, newValue in
                NotificationCenter.default.post(
                    name: .ignoreConcealedContentChanged,
                    object: nil,
                    userInfo: ["enabled": newValue]
                )
            }
        } header: {
            Text("Privacy")
        } footer: {
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(
                    "This feature relies on standard markers that most password managers use. Browser extensions may not always apply these markers."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Exclude Applications Section

    private var excludeApplicationsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Clipboard content from these apps will be ignored:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                // Excluded apps list
                if viewModel.excludedApps.isEmpty {
                    Text("No excluded apps")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    List(selection: Binding<ExcludedApp.ID?>(
                        get: { nil },
                        set: { _ in }
                    )) {
                        ForEach(viewModel.excludedApps) { app in
                            HStack(spacing: 12) {
                                ExcludedAppRow(app: app)
                                
                                Spacer()
                                
                                Button {
                                    viewModel.removeApp(id: app.id)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                                .help("Remove \(app.name)")
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.removeApp(id: app.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { indexSet in
                            viewModel.removeApps(at: indexSet)
                        }
                    }
                    .frame(minHeight: 100, maxHeight: 200)
                    .listStyle(.bordered)
                }
                
                // Error message
                if let error = viewModel.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // Add buttons
                HStack(spacing: 12) {
                    Button("Add App...") {
                        viewModel.showAppPicker = true
                    }
                    .controlSize(.regular)

                    Button("Add Bundle ID...") {
                        viewModel.showManualEntry = true
                    }
                    .controlSize(.regular)
                }
            }
        } header: {
            Text("Excluded Apps")
        } footer: {
            Text("Use 'Add App...' to browse installed applications or 'Add Bundle ID...' to manually enter a bundle identifier.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Excluded App Row

/// Row displaying an excluded app with icon and name
struct ExcludedAppRow: View {
    let app: ExcludedApp
    
    var body: some View {
        HStack(spacing: 12) {
            // App icon
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "app")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }
            
            // App info
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.body)
                
                Text(app.bundleID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontDesign(.monospaced)
            }
            
            Spacer()
            
            // Manual entry indicator
            if app.isManualEntry {
                Image(systemName: "text.badge.checkmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .help("Manually added")
            }
        }
        .padding(.vertical, 2)
    }
}
