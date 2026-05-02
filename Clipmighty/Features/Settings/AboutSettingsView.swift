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
        .alert(L10n.aboutAttachSupportLogTitle.text, isPresented: $showAttachLogPrompt) {
            Button(L10n.aboutAttachLog.text) {
                sendBugReport(includeLog: true)
            }
            Button(L10n.aboutNoThanks.text) {
                sendBugReport(includeLog: false)
            }
            Button(L10n.aboutCancel.text, role: .cancel) {}
        } message: {
            Text(L10n.aboutAttachSupportLogMessage.text)
        }
        .alert(L10n.aboutEmailErrorTitle.text, isPresented: $showEmailErrorAlert) {
            Button(L10n.aboutOK.text, role: .cancel) {}
        } message: {
            Text(L10n.aboutEmailErrorMessage.text)
        }
    }

    private var appInfoSection: some View {
        Section(L10n.settingsAboutTab.text) {
            HStack {
                Text(L10n.aboutVersion.text)
                Spacer()
                Text(AboutSupport.versionDescription())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var supportSection: some View {
        Section {
            Button(L10n.aboutReportBug.text) {
                showAttachLogPrompt = true
            }

            Button(L10n.aboutContact.text) {
                if !AboutSupport.openContactEmail() {
                    showEmailErrorAlert = true
                }
            }
        } header: {
            Text(L10n.aboutSupport.text)
        } footer: {
            Text(L10n.aboutSupportFooter.text)
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
