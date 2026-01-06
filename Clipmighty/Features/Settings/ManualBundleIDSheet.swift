//
//  ManualBundleIDSheet.swift
//  Clipmighty
//
//  Created on 2026-01-07.
//

import SwiftUI
import AppKit

/// Sheet for manually entering a bundle ID
struct ManualBundleIDSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var viewModel: ExcludedAppsViewModel
    
    @State private var bundleID = ""
    @State private var isValidating = false
    @State private var validationResult: ValidationResult?
    
    private let appDiscovery = AppDiscoveryService()
    
    enum ValidationResult {
        case valid(name: String, icon: NSImage?)
        case notFound
        case invalid
    }
    
    private var isValid: Bool {
        if case .valid = validationResult {
            return true
        }
        return false
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Bundle ID", text: $bundleID, prompt: Text("com.example.myapp"))
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                        .onChange(of: bundleID) { _, newValue in
                            validateBundleID(newValue)
                        }
                    
                    Text("Enter the bundle identifier of the application you want to exclude.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Bundle Identifier")
                }
                
                // Validation feedback
                if let result = validationResult {
                    Section {
                        switch result {
                        case .valid(let name, let icon):
                            HStack(spacing: 12) {
                                if let icon = icon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Application Found", systemImage: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text(name)
                                        .font(.body)
                                }
                            }
                            
                        case .notFound:
                            Label("Application not found on this system", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("You can still add this bundle ID, but the app may not be installed.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                        case .invalid:
                            Label("Invalid bundle ID format", systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text("Bundle IDs should follow the format: com.company.appname")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Validation")
                    }
                }
                
                // Error message from view model
                if let error = viewModel.errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            .frame(width: 500, height: 350)
            .navigationTitle("Add Bundle ID")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addBundleID()
                    }
                    .disabled(!canAdd)
                }
            }
        }
    }
    
    private var canAdd: Bool {
        // Can add if bundle ID is not empty and either valid or not found (but has correct format)
        guard !bundleID.isEmpty else { return false }
        
        switch validationResult {
        case .valid, .notFound:
            return true
        case .invalid, .none:
            return false
        }
    }
    
    private func validateBundleID(_ id: String) {
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            validationResult = nil
            return
        }
        
        // Check format first
        guard appDiscovery.validateBundleID(trimmed) else {
            validationResult = .invalid
            return
        }
        
        // Try to find the app
        if let appInfo = appDiscovery.getAppInfo(bundleID: trimmed) {
            validationResult = .valid(name: appInfo.name, icon: appInfo.icon)
        } else {
            validationResult = .notFound
        }
    }
    
    private func addBundleID() {
        let trimmed = bundleID.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if viewModel.validateAndAddManualBundleID(trimmed) {
            dismiss()
        }
        // Error message will be set by viewModel if validation fails
    }
}
