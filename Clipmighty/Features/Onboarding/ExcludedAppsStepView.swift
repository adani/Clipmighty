//
//  ExcludedAppsStepView.swift
//  Clipmighty
//
//  Created on 2026-01-09.
//

import SwiftUI
import AppKit

/// Excluded apps step view for onboarding
struct ExcludedAppsStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showAppPicker = false

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "app.badge.checkmark")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Excluded Apps")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("""
                    Clipboard content from these apps won't be saved. \
                    Great for password managers and sensitive apps.
                    """)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            .padding(.top, 24)

            // Apps list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.excludedApps) { app in
                        OnboardingExcludedAppRow(app: app, isExcluded: true) {
                            viewModel.toggleExcludedApp(app)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxHeight: 200)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 32)

            // Add app button
            Button(
                action: { showAppPicker = true },
                label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add Another App")
                    }
                }
            )
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)

            Spacer()
        }
        .sheet(isPresented: $showAppPicker) {
            OnboardingAppPickerSheet(viewModel: viewModel)
        }
        .task {
            await viewModel.loadInstalledApps()
        }
    }
}

/// App picker sheet for onboarding
struct OnboardingAppPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: OnboardingViewModel
    @State private var searchText = ""
    @State private var selectedApps: Set<AppDiscoveryService.InstalledApp> = []

    // Filter apps based on search text
    private var filteredApps: [AppDiscoveryService.InstalledApp] {
        if searchText.isEmpty {
            return viewModel.installedApps
        } else {
            return viewModel.installedApps.filter { app in
                app.name.localizedCaseInsensitiveContains(searchText) ||
                app.bundleID.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search applications...", text: $searchText)
                        .textFieldStyle(.plain)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
                .padding()

                Divider()

                // App list
                if viewModel.isLoadingApps {
                    VStack {
                        Spacer()
                        ProgressView("Loading applications...")
                        Spacer()
                    }
                } else if filteredApps.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "app.dashed")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text(searchText.isEmpty ? "No applications found" : "No matching applications")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.top)
                        Spacer()
                    }
                } else {
                    List(filteredApps, selection: $selectedApps) { app in
                        OnboardingAppPickerRow(
                            app: app,
                            isExcluded: viewModel.excludedApps.contains { $0.bundleID == app.bundleID },
                            isSelected: selectedApps.contains(app)
                        )
                        .tag(app)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleSelection(app)
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .frame(width: 500, height: 400)
            .navigationTitle("Select Applications to Exclude")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addApps(Array(selectedApps))
                        dismiss()
                    }
                    .disabled(selectedApps.isEmpty)
                }
            }
        }
    }

    private func toggleSelection(_ app: AppDiscoveryService.InstalledApp) {
        if selectedApps.contains(app) {
            selectedApps.remove(app)
        } else {
            selectedApps.insert(app)
        }
    }
}

/// Individual row in the onboarding app picker
struct OnboardingAppPickerRow: View {
    let app: AppDiscoveryService.InstalledApp
    let isExcluded: Bool
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // App icon
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "app")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
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

            // Status indicator
            if isExcluded {
                Label("Already excluded", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.green)
            } else if isSelected {
                Label("Selected", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
        .opacity(isExcluded ? 0.5 : 1.0)
    }
}

/// Row view for excluded apps in onboarding
struct OnboardingExcludedAppRow: View {
    let app: ExcludedApp
    let isExcluded: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // App icon
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "app")
                    .font(.title)
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
            }

            // App info
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.body)
                    .fontWeight(.medium)

                Text(app.bundleID)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: .constant(isExcluded))
                .toggleStyle(.checkbox)
                .labelsHidden()
                .onTapGesture {
                    onToggle()
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(8)
    }
}
