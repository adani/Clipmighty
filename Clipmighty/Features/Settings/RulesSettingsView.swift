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
    @AppStorage("keepPinnedItemsOnCleanup") private var keepPinnedItemsOnCleanup: Bool = true
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
                    Text(L10n.rulesIgnorePasswordManagerEntries.text)
                    Text(L10n.rulesIgnorePasswordManagerEntriesDescription.text)
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
            Text(L10n.rulesPrivacySection.text)
        } footer: {
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(L10n.rulesPrivacyFooter.text)
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
                Text(L10n.rulesExcludedAppsDescription.text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                // Excluded apps list
                if viewModel.excludedApps.isEmpty {
                    Text(L10n.rulesNoExcludedApps.text)
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
                                .help(L10n.rulesRemoveAppHelp.string(app.name))
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.removeApp(id: app.id)
                                } label: {
                                    Label(L10n.clipboardContextDelete.text, systemImage: "trash")
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
                    Button(L10n.rulesAddApp.text) {
                        viewModel.showAppPicker = true
                    }
                    .controlSize(.regular)

                    Button(L10n.rulesAddBundleID.text) {
                        viewModel.showManualEntry = true
                    }
                    .controlSize(.regular)
                }
            }
        } header: {
            Text(L10n.rulesExcludedAppsSection.text)
        } footer: {
            Text(L10n.rulesExcludedAppsFooter.text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - History Section
    
    private var historySection: some View {
        Section {
            Picker(L10n.rulesKeepHistory.text, selection: $selectedOption) {
                Text(RetentionOption.minutes30.localizedLabel).tag(RetentionOption.minutes30)
                Text(RetentionOption.hours8.localizedLabel).tag(RetentionOption.hours8)
                Text(RetentionOption.hours24.localizedLabel).tag(RetentionOption.hours24)
                Text(RetentionOption.days7.localizedLabel).tag(RetentionOption.days7)
                Divider()
                Text(RetentionOption.forever.localizedLabel).tag(RetentionOption.forever)
                Divider()
                Text(RetentionOption.custom.localizedLabel).tag(RetentionOption.custom)
            }
            .pickerStyle(.menu)
            .onChange(of: selectedOption) { _, _ in updateRetention() }

            if selectedOption == .custom {
                LabeledContent(L10n.rulesDuration.text) {
                    HStack(spacing: 8) {
                        TextField("", value: $customMinutes, format: .number)
                            .labelsHidden()
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)

                        Picker("", selection: $customUnit) {
                            Text(L10n.rulesMinutes.text).tag(TimeUnit.minutes)
                            Text(L10n.rulesHours.text).tag(TimeUnit.hours)
                            Text(L10n.rulesDays.text).tag(TimeUnit.days)
                        }
                        .labelsHidden()
                        .fixedSize()
                        .frame(minWidth: 100)
                    }
                }
                .onChange(of: customMinutes) { _, _ in updateRetention() }
                .onChange(of: customUnit) { _, _ in updateRetention() }
            }

            Toggle(L10n.rulesKeepPinnedItems.text, isOn: $keepPinnedItemsOnCleanup)
        } header: {
            Text(L10n.settingsHistorySection.text)
        } footer: {
            HStack {
                Spacer()
                Button(L10n.rulesClearAllHistory.text, role: .destructive) {
                    showingClearConfirmation = true
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
                .controlSize(.small)
            }
            .padding(.top, 8)
        }
        .confirmationDialog(
            L10n.rulesClearHistoryTitle.text,
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.rulesDeleteAll.text, role: .destructive) {
                clearHistory()
            }
            Button(L10n.rulesCancel.text, role: .cancel) {}
        } message: {
            Text(L10n.rulesClearHistoryMessage.text)
        }
    }
}

private extension RulesSettingsView {
    // MARK: - Helper Methods

    func initializeState() {
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

    func updateRetention() {
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

    func clearHistory() {
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
                    .help(L10n.rulesManuallyAdded.string)
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

    var localizedLabel: LocalizedStringKey {
        switch self {
        case .minutes30: return L10n.retentionMinutes30.text
        case .hours8: return L10n.retentionHours8.text
        case .hours24: return L10n.retentionHours24.text
        case .days7: return L10n.retentionDays7.text
        case .forever: return L10n.retentionForever.text
        case .custom: return L10n.retentionCustom.text
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
