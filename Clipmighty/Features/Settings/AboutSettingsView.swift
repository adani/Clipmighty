import SwiftUI

struct AboutSettingsView: View {
    @State private var showAttachLogPrompt = false
    @State private var showEmailErrorAlert = false

    var body: some View {
        Form {
            appInfoSection
            supportSection
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .alert("Attach support log?", isPresented: $showAttachLogPrompt) {
            Button("Attach Log") {
                sendBugReport(includeLog: true)
            }
            Button("No Thanks") {
                sendBugReport(includeLog: false)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Clipmighty can attach a support log to help diagnose the issue.")
        }
        .alert("Unable to compose email", isPresented: $showEmailErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please make sure a mail app is available and try again.")
        }
    }

    private var appInfoSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(AboutSupport.versionDescription())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var supportSection: some View {
        Section {
            Button("Report Bug") {
                showAttachLogPrompt = true
            }

            Button("Contact") {
                if !AboutSupport.openContactEmail() {
                    showEmailErrorAlert = true
                }
            }
        } header: {
            Text("Support")
        } footer: {
            Text("Report issues, feedback, and feature requests at support@nalarin.com.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func sendBugReport(includeLog: Bool) {
        if !AboutSupport.openBugReportEmail(includeLogAttachment: includeLog) {
            showEmailErrorAlert = true
        }
    }
}
