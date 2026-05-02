import Foundation
import SwiftUI

enum L10n {
    struct Entry {
        let key: String
        let defaultValue: String

        var text: LocalizedStringKey {
            LocalizedStringKey(key)
        }

        var string: String {
            Bundle.main.localizedString(forKey: key, value: defaultValue, table: nil)
        }

        func string(_ arguments: CVarArg...) -> String {
            String(format: string, arguments: arguments)
        }
    }

    static let appMenuTitle = Entry(key: "app.menu.title", defaultValue: "Clipmighty")
    static let appAboutMenuTitle = Entry(key: "app.menu.about", defaultValue: "About Clipmighty")

    static let clipboardSearchPlaceholder = Entry(
        key: "clipboard.search.placeholder",
        defaultValue: "Search clipboard..."
    )
    static let clipboardContextEdit = Entry(key: "clipboard.context.edit", defaultValue: "Edit")
    static let clipboardContextDelete = Entry(key: "clipboard.context.delete", defaultValue: "Delete")
    static let clipboardContextPin = Entry(key: "clipboard.context.pin", defaultValue: "Pin")
    static let clipboardContextUnpin = Entry(key: "clipboard.context.unpin", defaultValue: "Unpin")
    static let clipboardSynced = Entry(key: "clipboard.sync.synced", defaultValue: "iCloud Synced")
    static let clipboardRelativeAgo = Entry(key: "clipboard.sync.ago", defaultValue: "ago")
    static let clipboardDeleted = Entry(key: "clipboard.row.deleted", defaultValue: "Deleted")
    static let clipboardUndo = Entry(key: "clipboard.row.undo", defaultValue: "Undo")
    static let clipboardImageUnavailable = Entry(
        key: "clipboard.row.imageUnavailable",
        defaultValue: "Image (Unavailable)"
    )
    static let clipboardGeneratedImageLabel = Entry(
        key: "clipboard.generated.imageLabel",
        defaultValue: "Image %@"
    )
    static let clipboardRichTextContent = Entry(
        key: "clipboard.generated.richTextContent",
        defaultValue: "Rich Text Content"
    )

    static let editTitle = Entry(key: "edit.title", defaultValue: "Edit Clipboard Item")
    static let editCancel = Entry(key: "edit.cancel", defaultValue: "Cancel")
    static let editSaveCopy = Entry(key: "edit.saveCopy", defaultValue: "Save Copy")

    static let overlayTitle = Entry(key: "overlay.title", defaultValue: "Clipboard History")
    static let overlayEmptyTitle = Entry(key: "overlay.empty.title", defaultValue: "No Clipboard History")
    static let overlayEmptyMessage = Entry(
        key: "overlay.empty.message",
        defaultValue: "Copy something to see it here."
    )
    static let overlayPinInstruction = Entry(
        key: "overlay.instruction.pin",
        defaultValue: "Use %@ to pin/unpin"
    )
    static let overlayPasteInstruction = Entry(
        key: "overlay.instruction.paste",
        defaultValue: "↵ to paste • %@"
    )
    static let overlayCopyInstruction = Entry(
        key: "overlay.instruction.copy",
        defaultValue: "↵ to copy • %@"
    )
    static let overlayImage = Entry(key: "overlay.image", defaultValue: "Image")
    static let toastCopied = Entry(key: "toast.copied", defaultValue: "Copied")
    static let dateYesterdayFormat = Entry(key: "date.yesterday.format", defaultValue: "Yesterday, %@")

    static let settingsGeneralTab = Entry(key: "settings.general.tab", defaultValue: "General")
    static let settingsRulesTab = Entry(key: "settings.rules.tab", defaultValue: "Rules")
    static let settingsSyncTab = Entry(key: "settings.sync.tab", defaultValue: "Sync")
    static let settingsAboutTab = Entry(key: "settings.about.tab", defaultValue: "About")
    static let settingsStartupSection = Entry(key: "settings.general.startup", defaultValue: "Startup")
    static let settingsLaunchAtLogin = Entry(
        key: "settings.general.launchAtLogin",
        defaultValue: "Launch at Login"
    )
    static let settingsHistorySection = Entry(key: "settings.history.section", defaultValue: "History")
    static let settingsMoveCopiedItemToTop = Entry(
        key: "settings.history.moveCopiedItemToTop",
        defaultValue: "Move copied history item to top"
    )
    static let settingsPasteOverlay = Entry(
        key: "settings.shortcut.pasteOverlay",
        defaultValue: "Paste Overlay:"
    )
    static let settingsPinUnpinOverlay = Entry(
        key: "settings.shortcut.pinUnpinOverlay",
        defaultValue: "Pin/Unpin in Overlay:"
    )
    static let settingsKeyboardShortcut = Entry(
        key: "settings.shortcut.section",
        defaultValue: "Keyboard Shortcut"
    )
    static let settingsKeyboardShortcutFooter = Entry(
        key: "settings.shortcut.footer",
        defaultValue: "Set shortcuts for opening the paste overlay and pinning items in it. The shortcut must include at least one modifier key (⌘, ⇧, ⌥, or ⌃)."
    )
    static let settingsDirectPaste = Entry(
        key: "settings.permissions.directPaste",
        defaultValue: "Direct Paste from Overlay"
    )
    static let settingsEnabled = Entry(key: "settings.permissions.enabled", defaultValue: "Enabled")
    static let settingsDisabled = Entry(key: "settings.permissions.disabled", defaultValue: "Disabled")
    static let settingsDisableAccessibility = Entry(
        key: "settings.permissions.disableAccessibility",
        defaultValue: "Disable in Accessibility Settings"
    )
    static let settingsEnableAccessibility = Entry(
        key: "settings.permissions.enableAccessibility",
        defaultValue: "Enable in Accessibility Settings"
    )
    static let settingsAssistivePaste = Entry(
        key: "settings.permissions.assistivePaste",
        defaultValue: "Assistive Paste"
    )
    static let settingsAssistivePasteFooter = Entry(
        key: "settings.permissions.footer",
        defaultValue: "Allows Clipmighty to insert selected items directly into the active window. This reduces the need for repetitive manual keystrokes and complex key chords."
    )

    static let rulesIgnorePasswordManagerEntries = Entry(
        key: "settings.rules.ignorePasswordManagerEntries",
        defaultValue: "Ignore password manager entries"
    )
    static let rulesIgnorePasswordManagerEntriesDescription = Entry(
        key: "settings.rules.ignorePasswordManagerEntries.description",
        defaultValue: "Detects and skips clipboard content marked as private or auto-generated."
    )
    static let rulesPrivacySection = Entry(key: "settings.rules.privacy", defaultValue: "Privacy")
    static let rulesPrivacyFooter = Entry(
        key: "settings.rules.privacy.footer",
        defaultValue: "This feature relies on standard markers that most password managers use. Browser extensions may not always apply these markers."
    )
    static let rulesExcludedAppsSection = Entry(
        key: "settings.rules.excludedApps",
        defaultValue: "Excluded Apps"
    )
    static let rulesExcludedAppsDescription = Entry(
        key: "settings.rules.excludedApps.description",
        defaultValue: "Clipboard content from these apps will be ignored:"
    )
    static let rulesNoExcludedApps = Entry(
        key: "settings.rules.noExcludedApps",
        defaultValue: "No excluded apps"
    )
    static let rulesRemoveAppHelp = Entry(
        key: "settings.rules.removeApp.help",
        defaultValue: "Remove %@"
    )
    static let rulesAddApp = Entry(key: "settings.rules.addApp", defaultValue: "Add App...")
    static let rulesAddBundleID = Entry(
        key: "settings.rules.addBundleID",
        defaultValue: "Add Bundle ID..."
    )
    static let rulesExcludedAppsFooter = Entry(
        key: "settings.rules.excludedApps.footer",
        defaultValue: "Use 'Add App...' to browse installed applications or 'Add Bundle ID...' to manually enter a bundle identifier."
    )
    static let rulesKeepHistory = Entry(key: "settings.history.keepHistory", defaultValue: "Keep history:")
    static let rulesDuration = Entry(key: "settings.history.duration", defaultValue: "Duration:")
    static let rulesMinutes = Entry(key: "settings.history.minutes", defaultValue: "Minutes")
    static let rulesHours = Entry(key: "settings.history.hours", defaultValue: "Hours")
    static let rulesDays = Entry(key: "settings.history.days", defaultValue: "Days")
    static let rulesKeepPinnedItems = Entry(
        key: "settings.history.keepPinnedItems",
        defaultValue: "Keep pinned items"
    )
    static let rulesClearAllHistory = Entry(
        key: "settings.history.clearAll",
        defaultValue: "Clear All History…"
    )
    static let rulesClearHistoryTitle = Entry(
        key: "settings.history.clear.title",
        defaultValue: "Clear Clipboard History?"
    )
    static let rulesDeleteAll = Entry(key: "settings.history.deleteAll", defaultValue: "Delete All")
    static let rulesCancel = Entry(key: "settings.cancel", defaultValue: "Cancel")
    static let rulesClearHistoryMessage = Entry(
        key: "settings.history.clear.message",
        defaultValue: "This will permanently delete all clipboard history. This action cannot be undone."
    )
    static let rulesManuallyAdded = Entry(
        key: "settings.rules.manuallyAdded",
        defaultValue: "Manually added"
    )
    static let retentionMinutes30 = Entry(key: "settings.history.retention.minutes30", defaultValue: "30 Minutes")
    static let retentionHours8 = Entry(key: "settings.history.retention.hours8", defaultValue: "8 Hours")
    static let retentionHours24 = Entry(key: "settings.history.retention.hours24", defaultValue: "24 Hours")
    static let retentionDays7 = Entry(key: "settings.history.retention.days7", defaultValue: "7 Days")
    static let retentionForever = Entry(key: "settings.history.retention.forever", defaultValue: "Forever")
    static let retentionCustom = Entry(key: "settings.history.retention.custom", defaultValue: "Custom...")

    static let syncRestartTitle = Entry(key: "settings.sync.restart.title", defaultValue: "Restart Required")
    static let syncRestartNow = Entry(key: "settings.sync.restart.now", defaultValue: "Restart Now")
    static let syncLater = Entry(key: "settings.sync.restart.later", defaultValue: "Later")
    static let syncRestartMessage = Entry(
        key: "settings.sync.restart.message",
        defaultValue: "Clipmighty needs to restart to apply changes to sync settings."
    )
    static let syncWithICloud = Entry(key: "settings.sync.icloud.toggle", defaultValue: "Sync with iCloud")
    static let syncICloudEnabledDescription = Entry(
        key: "settings.sync.icloud.enabledDescription",
        defaultValue: "Clipboard history syncs across your devices signed into the same iCloud account."
    )
    static let syncICloudDisabledDescription = Entry(
        key: "settings.sync.icloud.disabledDescription",
        defaultValue: "Enable to sync clipboard history across your devices."
    )
    static let syncICloudSection = Entry(key: "settings.sync.icloud.section", defaultValue: "iCloud")

    static let aboutAttachSupportLogTitle = Entry(
        key: "settings.about.attachSupportLog.title",
        defaultValue: "Attach support log?"
    )
    static let aboutAttachLog = Entry(key: "settings.about.attachLog", defaultValue: "Attach Log")
    static let aboutNoThanks = Entry(key: "settings.about.noThanks", defaultValue: "No Thanks")
    static let aboutCancel = Entry(key: "settings.about.cancel", defaultValue: "Cancel")
    static let aboutAttachSupportLogMessage = Entry(
        key: "settings.about.attachSupportLog.message",
        defaultValue: "Clipmighty can attach a support log to help diagnose the issue."
    )
    static let aboutEmailErrorTitle = Entry(
        key: "settings.about.emailError.title",
        defaultValue: "Unable to compose email"
    )
    static let aboutOK = Entry(key: "settings.about.ok", defaultValue: "OK")
    static let aboutEmailErrorMessage = Entry(
        key: "settings.about.emailError.message",
        defaultValue: "Please make sure a mail app is available and try again."
    )
    static let aboutVersion = Entry(key: "settings.about.version", defaultValue: "Version")
    static let aboutReportBug = Entry(key: "settings.about.reportBug", defaultValue: "Report Bug")
    static let aboutContact = Entry(key: "settings.about.contact", defaultValue: "Contact")
    static let aboutSupport = Entry(key: "settings.about.support", defaultValue: "Support")
    static let aboutSupportFooter = Entry(
        key: "settings.about.support.footer",
        defaultValue: "Report issues, feedback, and feature requests at support@nalarin.com."
    )

    static let appPickerSearchPlaceholder = Entry(
        key: "appPicker.search.placeholder",
        defaultValue: "Search applications..."
    )
    static let appPickerLoading = Entry(key: "appPicker.loading", defaultValue: "Loading applications...")
    static let appPickerNoApplications = Entry(
        key: "appPicker.noApplications",
        defaultValue: "No applications found"
    )
    static let appPickerNoMatchingApplications = Entry(
        key: "appPicker.noMatchingApplications",
        defaultValue: "No matching applications"
    )
    static let appPickerTitle = Entry(
        key: "appPicker.title",
        defaultValue: "Select Applications to Exclude"
    )
    static let appPickerCancel = Entry(key: "appPicker.cancel", defaultValue: "Cancel")
    static let appPickerAdd = Entry(key: "appPicker.add", defaultValue: "Add")
    static let appPickerAlreadyExcluded = Entry(
        key: "appPicker.alreadyExcluded",
        defaultValue: "Already excluded"
    )
    static let appPickerSelected = Entry(key: "appPicker.selected", defaultValue: "Selected")

    static let manualBundleIDField = Entry(key: "manualBundleID.field", defaultValue: "Bundle ID")
    static let manualBundleIDPrompt = Entry(key: "manualBundleID.prompt", defaultValue: "com.example.myapp")
    static let manualBundleIDDescription = Entry(
        key: "manualBundleID.description",
        defaultValue: "Enter the bundle identifier of the application you want to exclude."
    )
    static let manualBundleIDSection = Entry(
        key: "manualBundleID.section",
        defaultValue: "Bundle Identifier"
    )
    static let manualBundleIDApplicationFound = Entry(
        key: "manualBundleID.applicationFound",
        defaultValue: "Application Found"
    )
    static let manualBundleIDNotFound = Entry(
        key: "manualBundleID.notFound",
        defaultValue: "Application not found on this system"
    )
    static let manualBundleIDNotFoundDescription = Entry(
        key: "manualBundleID.notFound.description",
        defaultValue: "You can still add this bundle ID, but the app may not be installed."
    )
    static let manualBundleIDInvalid = Entry(
        key: "manualBundleID.invalid",
        defaultValue: "Invalid bundle ID format"
    )
    static let manualBundleIDInvalidDescription = Entry(
        key: "manualBundleID.invalid.description",
        defaultValue: "Bundle IDs should follow the format: com.company.appname"
    )
    static let manualBundleIDValidation = Entry(
        key: "manualBundleID.validation",
        defaultValue: "Validation"
    )
    static let manualBundleIDTitle = Entry(key: "manualBundleID.title", defaultValue: "Add Bundle ID")

    static let onboardingBack = Entry(key: "onboarding.back", defaultValue: "Back")
    static let onboardingGetStarted = Entry(key: "onboarding.getStarted", defaultValue: "Get Started")
    static let onboardingContinue = Entry(key: "onboarding.continue", defaultValue: "Continue")
    static let onboardingWelcomeTitle = Entry(
        key: "onboarding.welcome.title",
        defaultValue: "Welcome to Clipmighty"
    )
    static let onboardingWelcomeSubtitle = Entry(
        key: "onboarding.welcome.subtitle",
        defaultValue: "Your powerful clipboard manager"
    )
    static let onboardingTermsPrefix = Entry(
        key: "onboarding.welcome.termsPrefix",
        defaultValue: "By continuing, you agree to our"
    )
    static let onboardingTermsOfService = Entry(
        key: "onboarding.welcome.terms",
        defaultValue: "Terms of Service"
    )
    static let onboardingTermsAnd = Entry(key: "onboarding.welcome.and", defaultValue: "and")
    static let onboardingPrivacyPolicy = Entry(
        key: "onboarding.welcome.privacy",
        defaultValue: "Privacy Policy"
    )
    static let onboardingFeatureInstantHistory = Entry(
        key: "onboarding.feature.instantHistory",
        defaultValue: "📋 Instant clipboard history"
    )
    static let onboardingFeaturePowerfulSearch = Entry(
        key: "onboarding.feature.powerfulSearch",
        defaultValue: "🔍 Powerful search"
    )
    static let onboardingFeatureKeyboardShortcuts = Entry(
        key: "onboarding.feature.keyboardShortcuts",
        defaultValue: "⌨️ Quick keyboard shortcuts"
    )
    static let onboardingFeaturePrivacyFocused = Entry(
        key: "onboarding.feature.privacyFocused",
        defaultValue: "🔒 Privacy-focused design"
    )
    static let onboardingFeatureICloudSync = Entry(
        key: "onboarding.feature.icloudSync",
        defaultValue: "☁️ iCloud sync support"
    )
    static let onboardingFeatureAppExclusions = Entry(
        key: "onboarding.feature.appExclusions",
        defaultValue: "🚫 App exclusion rules"
    )
    static let onboardingExcludedAppsTitle = Entry(
        key: "onboarding.excludedApps.title",
        defaultValue: "Excluded Apps"
    )
    static let onboardingExcludedAppsDescription = Entry(
        key: "onboarding.excludedApps.description",
        defaultValue: "Clipboard content from these apps won't be saved. Great for password managers and sensitive apps."
    )
    static let onboardingAddAnotherApp = Entry(
        key: "onboarding.excludedApps.addAnother",
        defaultValue: "Add Another App"
    )
    static let onboardingTutorialSampleHello = Entry(
        key: "onboarding.tutorial.sample.hello",
        defaultValue: "Hello from Clipmighty! 🎉"
    )
    static let onboardingTutorialSampleCopyMe = Entry(
        key: "onboarding.tutorial.sample.copyMe",
        defaultValue: "Copy me and paste below!"
    )
    static let onboardingTutorialSampleHistory = Entry(
        key: "onboarding.tutorial.sample.history",
        defaultValue: "Your clipboard history awaits"
    )
    static let onboardingTutorialTitle = Entry(
        key: "onboarding.tutorial.title",
        defaultValue: "Quick Tutorial"
    )
    static let onboardingTutorialDescription = Entry(
        key: "onboarding.tutorial.description",
        defaultValue: "Let's try out Clipmighty! Copy one of the texts below, then paste it using the shortcut."
    )
    static let onboardingTutorialClickToCopy = Entry(
        key: "onboarding.tutorial.clickToCopy",
        defaultValue: "Click to copy:"
    )
    static let onboardingTutorialMenuBarTitle = Entry(
        key: "onboarding.tutorial.menuBar.title",
        defaultValue: "Find Clipmighty in your menu bar"
    )
    static let onboardingTutorialMenuBarDescription = Entry(
        key: "onboarding.tutorial.menuBar.description",
        defaultValue: "Click the clipboard icon or use ⌃V to see your history"
    )
    static let onboardingTutorialPasteLabel = Entry(
        key: "onboarding.tutorial.pasteLabel",
        defaultValue: "Paste here to complete:"
    )
    static let onboardingTutorialPastePlaceholder = Entry(
        key: "onboarding.tutorial.pastePlaceholder",
        defaultValue: "Paste here..."
    )
    static let onboardingTutorialGreat = Entry(key: "onboarding.tutorial.great", defaultValue: "Great!")
    static let onboardingTutorialReady = Entry(
        key: "onboarding.tutorial.ready",
        defaultValue: "You're ready to use Clipmighty!"
    )
    static let onboardingPermissionsTitle = Entry(
        key: "onboarding.permissions.title",
        defaultValue: "Enable Overlay Auto-Paste"
    )
    static let onboardingPermissionsDescription = Entry(
        key: "onboarding.permissions.description",
        defaultValue: "To automatically insert history items directly into your active apps, Clipmighty needs Accessibility permission. This allows our overlay to simulate the \"Paste\" command for you, saving you manual effort."
    )
    static let onboardingPermissionGranted = Entry(
        key: "onboarding.permissions.granted",
        defaultValue: "Permission Granted"
    )
    static let onboardingPermissionRequired = Entry(
        key: "onboarding.permissions.required",
        defaultValue: "Permission Required"
    )
    static let onboardingOpenSystemSettings = Entry(
        key: "onboarding.permissions.openSystemSettings",
        defaultValue: "Open System Settings"
    )
    static let onboardingPrivacyFirst = Entry(
        key: "onboarding.permissions.privacyFirst",
        defaultValue: "Privacy First"
    )
    static let onboardingPrivacyFirstDescription = Entry(
        key: "onboarding.permissions.privacyFirst.description",
        defaultValue: "This permission is strictly used to simulate the 'Paste' command and identify source apps. Your clipboard history remains local and is never transmitted."
    )

    static let quitAlertTitle = Entry(key: "quit.alert.title", defaultValue: "Quit Clipmighty?")
    static let quitAlertMessage = Entry(
        key: "quit.alert.message",
        defaultValue: "Are you sure you want to quit the application? It will stop monitoring your clipboard."
    )
    static let quitAlertQuit = Entry(key: "quit.alert.quit", defaultValue: "Quit")
    static let quitAlertCancel = Entry(key: "quit.alert.cancel", defaultValue: "Cancel")

    static let shortcutValidationNoModifier = Entry(
        key: "shortcut.validation.noModifier",
        defaultValue: "Please use at least one modifier key (⌘, ⇧, ⌥, or ⌃)"
    )
    static let shortcutValidationConflict = Entry(
        key: "shortcut.validation.conflict",
        defaultValue: "Conflicts with system shortcut: %@"
    )
    static let shortcutValidationInvalidTitle = Entry(
        key: "shortcut.validation.invalid.title",
        defaultValue: "Invalid Shortcut"
    )
    static let shortcutValidationOK = Entry(key: "shortcut.validation.ok", defaultValue: "OK")
    static let shortcutRecordingPlaceholder = Entry(
        key: "shortcut.recording.placeholder",
        defaultValue: "Press shortcut..."
    )
    static let shortcutKeySpace = Entry(key: "shortcut.key.space", defaultValue: "Space")
    static let shortcutSystemQuitApplication = Entry(
        key: "shortcut.system.quitApplication",
        defaultValue: "Quit Application"
    )
    static let shortcutSystemCloseWindow = Entry(
        key: "shortcut.system.closeWindow",
        defaultValue: "Close Window"
    )
    static let shortcutSystemMinimizeWindow = Entry(
        key: "shortcut.system.minimizeWindow",
        defaultValue: "Minimize Window"
    )
    static let shortcutSystemHideApplication = Entry(
        key: "shortcut.system.hideApplication",
        defaultValue: "Hide Application"
    )
    static let shortcutSystemPreferences = Entry(
        key: "shortcut.system.preferences",
        defaultValue: "Preferences"
    )
    static let shortcutSystemSelectAll = Entry(
        key: "shortcut.system.selectAll",
        defaultValue: "Select All"
    )
    static let shortcutSystemCopy = Entry(key: "shortcut.system.copy", defaultValue: "Copy")
    static let shortcutSystemCut = Entry(key: "shortcut.system.cut", defaultValue: "Cut")
    static let shortcutSystemPaste = Entry(key: "shortcut.system.paste", defaultValue: "Paste")
    static let shortcutSystemUndo = Entry(key: "shortcut.system.undo", defaultValue: "Undo")
    static let shortcutSystemSpotlight = Entry(
        key: "shortcut.system.spotlight",
        defaultValue: "Spotlight"
    )
    static let shortcutSystemSwitchApps = Entry(
        key: "shortcut.system.switchApps",
        defaultValue: "Switch Apps"
    )
    static let shortcutSystemEmojiSymbols = Entry(
        key: "shortcut.system.emojiSymbols",
        defaultValue: "Emoji & Symbols"
    )

    static let supportVersionUnknown = Entry(
        key: "support.version.unknown",
        defaultValue: "Version Unknown"
    )
    static let supportVersionBuildFormat = Entry(
        key: "support.version.buildFormat",
        defaultValue: "Version %@ (Build %@)"
    )
    static let supportVersionFormat = Entry(key: "support.version.format", defaultValue: "Version %@")
    static let supportContactSubject = Entry(
        key: "support.contact.subject",
        defaultValue: "Feedback for Clipmighty"
    )
    static let supportContactBody = Entry(
        key: "support.contact.body",
        defaultValue: "Hi Clipmighty team,"
    )
    static let supportBugReportSubject = Entry(
        key: "support.bugReport.subject",
        defaultValue: "Bug Report for Clipmighty"
    )
    static let supportLogTitle = Entry(key: "support.log.title", defaultValue: "Clipmighty Support Log")
    static let supportLogGeneratedFormat = Entry(
        key: "support.log.generatedFormat",
        defaultValue: "Generated: %@"
    )
    static let supportLogMacOSFormat = Entry(key: "support.log.macOSFormat", defaultValue: "macOS: %@")
    static let supportLogPreferencesSnapshot = Entry(
        key: "support.log.preferencesSnapshot",
        defaultValue: "Preferences Snapshot:"
    )
    static let supportBugIssueDescription = Entry(
        key: "support.bug.issueDescription",
        defaultValue: "Issue description:"
    )
    static let supportBugExpectedBehavior = Entry(
        key: "support.bug.expectedBehavior",
        defaultValue: "Expected behavior:"
    )
    static let supportBugActualBehavior = Entry(
        key: "support.bug.actualBehavior",
        defaultValue: "Actual behavior:"
    )
    static let supportBugTimestampFormat = Entry(
        key: "support.bug.timestampFormat",
        defaultValue: "Timestamp: %@"
    )

    static let errorLoadApplications = Entry(
        key: "error.loadApplications",
        defaultValue: "Failed to load applications: %@"
    )
    static let errorAppAlreadyExcluded = Entry(
        key: "error.appAlreadyExcluded",
        defaultValue: "App is already excluded"
    )
    static let errorInvalidBundleID = Entry(
        key: "error.invalidBundleID",
        defaultValue: "Invalid bundle ID format. Expected format: com.example.app"
    )
    static let errorSaveChanges = Entry(key: "error.saveChanges", defaultValue: "Failed to save changes")
    static let defaultAppKeychainAccess = Entry(
        key: "defaultApp.keychainAccess",
        defaultValue: "Keychain Access"
    )

    static let allEntries: [Entry] = [
        appMenuTitle, appAboutMenuTitle, clipboardSearchPlaceholder, clipboardContextEdit,
        clipboardContextDelete, clipboardContextPin, clipboardContextUnpin, clipboardSynced,
        clipboardRelativeAgo, clipboardDeleted, clipboardUndo, clipboardImageUnavailable,
        clipboardGeneratedImageLabel, clipboardRichTextContent, editTitle, editCancel,
        editSaveCopy, overlayTitle, overlayEmptyTitle, overlayEmptyMessage, overlayPinInstruction,
        overlayPasteInstruction, overlayCopyInstruction, overlayImage, toastCopied, dateYesterdayFormat,
        settingsGeneralTab, settingsRulesTab, settingsSyncTab, settingsAboutTab,
        settingsStartupSection, settingsLaunchAtLogin, settingsHistorySection,
        settingsMoveCopiedItemToTop, settingsPasteOverlay, settingsPinUnpinOverlay,
        settingsKeyboardShortcut, settingsKeyboardShortcutFooter, settingsDirectPaste,
        settingsEnabled, settingsDisabled, settingsDisableAccessibility, settingsEnableAccessibility,
        settingsAssistivePaste, settingsAssistivePasteFooter, rulesIgnorePasswordManagerEntries,
        rulesIgnorePasswordManagerEntriesDescription, rulesPrivacySection, rulesPrivacyFooter,
        rulesExcludedAppsSection, rulesExcludedAppsDescription, rulesNoExcludedApps,
        rulesRemoveAppHelp, rulesAddApp, rulesAddBundleID, rulesExcludedAppsFooter,
        rulesKeepHistory, rulesDuration, rulesMinutes, rulesHours, rulesDays, rulesKeepPinnedItems,
        rulesClearAllHistory, rulesClearHistoryTitle, rulesDeleteAll, rulesCancel,
        rulesClearHistoryMessage, rulesManuallyAdded, retentionMinutes30, retentionHours8,
        retentionHours24, retentionDays7, retentionForever, retentionCustom, syncRestartTitle,
        syncRestartNow, syncLater, syncRestartMessage, syncWithICloud,
        syncICloudEnabledDescription, syncICloudDisabledDescription, syncICloudSection,
        aboutAttachSupportLogTitle, aboutAttachLog, aboutNoThanks, aboutCancel,
        aboutAttachSupportLogMessage, aboutEmailErrorTitle, aboutOK, aboutEmailErrorMessage,
        aboutVersion, aboutReportBug, aboutContact, aboutSupport, aboutSupportFooter,
        appPickerSearchPlaceholder, appPickerLoading, appPickerNoApplications,
        appPickerNoMatchingApplications, appPickerTitle, appPickerCancel, appPickerAdd,
        appPickerAlreadyExcluded, appPickerSelected, manualBundleIDField, manualBundleIDPrompt,
        manualBundleIDDescription, manualBundleIDSection, manualBundleIDApplicationFound,
        manualBundleIDNotFound, manualBundleIDNotFoundDescription, manualBundleIDInvalid,
        manualBundleIDInvalidDescription, manualBundleIDValidation, manualBundleIDTitle,
        onboardingBack, onboardingGetStarted, onboardingContinue, onboardingWelcomeTitle,
        onboardingWelcomeSubtitle, onboardingTermsPrefix, onboardingTermsOfService,
        onboardingTermsAnd, onboardingPrivacyPolicy, onboardingFeatureInstantHistory,
        onboardingFeaturePowerfulSearch, onboardingFeatureKeyboardShortcuts,
        onboardingFeaturePrivacyFocused, onboardingFeatureICloudSync, onboardingFeatureAppExclusions,
        onboardingExcludedAppsTitle, onboardingExcludedAppsDescription, onboardingAddAnotherApp,
        onboardingTutorialSampleHello, onboardingTutorialSampleCopyMe, onboardingTutorialSampleHistory,
        onboardingTutorialTitle, onboardingTutorialDescription, onboardingTutorialClickToCopy,
        onboardingTutorialMenuBarTitle, onboardingTutorialMenuBarDescription,
        onboardingTutorialPasteLabel, onboardingTutorialPastePlaceholder, onboardingTutorialGreat,
        onboardingTutorialReady, onboardingPermissionsTitle, onboardingPermissionsDescription,
        onboardingPermissionGranted, onboardingPermissionRequired, onboardingOpenSystemSettings,
        onboardingPrivacyFirst, onboardingPrivacyFirstDescription, quitAlertTitle, quitAlertMessage, quitAlertQuit, quitAlertCancel,
        shortcutValidationNoModifier, shortcutValidationConflict, shortcutValidationInvalidTitle,
        shortcutValidationOK, shortcutRecordingPlaceholder, shortcutKeySpace,
        shortcutSystemQuitApplication, shortcutSystemCloseWindow, shortcutSystemMinimizeWindow,
        shortcutSystemHideApplication, shortcutSystemPreferences, shortcutSystemSelectAll,
        shortcutSystemCopy, shortcutSystemCut, shortcutSystemPaste, shortcutSystemUndo,
        shortcutSystemSpotlight, shortcutSystemSwitchApps, shortcutSystemEmojiSymbols,
        supportVersionUnknown, supportVersionBuildFormat, supportVersionFormat,
        supportContactSubject, supportContactBody, supportBugReportSubject, supportLogTitle,
        supportLogGeneratedFormat, supportLogMacOSFormat, supportLogPreferencesSnapshot,
        supportBugIssueDescription, supportBugExpectedBehavior, supportBugActualBehavior,
        supportBugTimestampFormat, errorLoadApplications, errorAppAlreadyExcluded,
        errorInvalidBundleID, errorSaveChanges, defaultAppKeychainAccess
    ]
}
