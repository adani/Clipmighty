//
//  RulesSettingsView.swift
//  Clipmighty
//
//  Rules settings tab for privacy protection and app exclusions.
//

import SwiftUI
import SwiftData

struct RulesSettingsView: View {
    @AppStorage("ignoreConcealedContent") private var ignoreConcealedContent: Bool = true
    @Environment(ClipboardMonitor.self) private var monitor
    @Environment(\.modelContext) private var modelContext
    @Binding var retentionDuration: Int // seconds
    @State private var viewModel: ExcludedAppsViewModel
    
    // History retention state
    @State private var showingClearConfirmation = false
    @State private var customMinutes: Int = 30
    @State private var customUnit: TimeUnit = .minutes
    @State private var selectedOption: RetentionOption = .days7

    init(monitor: ClipboardMonitor, retentionDuration: Binding<Int>) {
        _viewModel = State(initialValue: ExcludedAppsViewModel(monitor: monitor))
        _retentionDuration = retentionDuration
    }

    var body: some View {
        Form {
            historySection
            privacyProtectionSection
            excludeApplicationsSection
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .onAppear {
            initializeState()
        }
        .onChange(of: retentionDuration) { _, newValue in
            let newOption = RetentionOption.from(seconds: newValue)
            if newOption != .custom && newOption != selectedOption {
                selectedOption = newOption
            }
        }
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
                    "This feature relies on standard markers that most password managers use. " +
                    "Browser extensions may not always apply these markers."
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
            Text("Use 'Add App...' to browse installed applications or 'Add Bundle ID...' " +
                 "to manually enter a bundle identifier.")
                .font(.caption)
                .foregroundStyle(.secondary)
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
        } header: {
            Text("History")
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
    
    // MARK: - Helper Methods
    
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
    
    private func clearHistory() {
        do {
            try modelContext.delete(model: ClipboardItem.self)
        } catch {
            print("Failed to clear history: \(error)")
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

// MARK: - Supporting Types

private enum TimeUnit: String, CaseIterable, Identifiable {
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

private enum RetentionOption: Hashable {
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
