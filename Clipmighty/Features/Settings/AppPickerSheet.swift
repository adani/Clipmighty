//
//  AppPickerSheet.swift
//  Clipmighty
//
//  Created on 2026-01-07.
//

import SwiftUI
import AppKit

/// Sheet for selecting applications to exclude from clipboard monitoring
struct AppPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var viewModel: ExcludedAppsViewModel
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
                        AppPickerRow(
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
            .frame(width: 600, height: 500)
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

/// Individual row in the app picker
struct AppPickerRow: View {
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
