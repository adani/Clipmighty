import SwiftData
import SwiftUI

@main
struct ClipmightyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var monitor = ClipboardMonitor()

    static var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ClipboardItem.self
        ])

        // Check for Test Mode
        let isTestMode = ProcessInfo.processInfo.arguments.contains("-enableTestMode")

        if isTestMode {
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

                // Seed mock data for UI tests
                Task { @MainActor in
                    PreviewData.insertMockData(context: container.mainContext)
                }

                print("[Clipmighty] Started in TEST MODE with in-memory container and mock data")
                return container
            } catch {
                fatalError("Could not create Test ModelContainer: \(error)")
            }
        }

        // Read the user's sync preference (defaulting to false if not set)
        let isCloudSyncEnabled = UserDefaults.standard.bool(forKey: "enableCloudSync")

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: isCloudSyncEnabled ? .automatic : .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        MenuBarExtra("Clipmighty", systemImage: "clipboard") {
            ContentView()
                .environment(monitor)
                .modelContainer(ClipmightyApp.sharedModelContainer)
                .task {
                    // Run purge on a background actor
                    let container = ClipmightyApp.sharedModelContainer
                    Task { @MainActor in
                        let context = ModelContext(container)
                        ClipmightyApp.purgeOldItems(context: context)
                    }
                }
        }
        .menuBarExtraStyle(.window)  // Use .window for the popover "Liquid" style view

        Settings {
            SettingsView()
                .environment(monitor)
                .modelContainer(ClipmightyApp.sharedModelContainer)
        }
    }

    init() {
        // Enable "Launch at Login" on first launch
        LaunchAtLoginService.enableOnFirstLaunchIfNeeded()

        // Pass monitor reference to AppDelegate
        appDelegate.clipboardMonitor = monitor

        // Set up the clipboard callback BEFORE starting monitoring
        // This is critical: previously the callback was set in ContentView.onAppear(),
        // which meant clipboard changes were detected but NOT saved until the menu was opened.
        let container = ClipmightyApp.sharedModelContainer
        monitor.onNewItem = { item in
            Task { @MainActor in
                let context = ModelContext(container)

                // Smart Deduplication Logic:
                // Check if an identical item exists from the same app within the last 1 hour.
                let oneHourAgo = Date().addingTimeInterval(-3600)
                let itemHash = item.contentHash
                let itemBundleID = item.sourceAppBundleID

                var isDuplicate = false

                // Only perform deduplication if we have a hash (text content)
                if let hash = itemHash {
                    let descriptor = FetchDescriptor<ClipboardItem>(
                        predicate: #Predicate<ClipboardItem> { existing in
                            existing.contentHash == hash &&
                            existing.sourceAppBundleID == itemBundleID &&
                            existing.timestamp > oneHourAgo
                        }
                    )

                    if let existingItem = try? context.fetch(descriptor).first {
                        // Found a duplicate: Update timestamp to now (move to top)
                        existingItem.timestamp = Date()
                        // Update app name just in case it changed (unlikely for same bundleID)
                        if let newAppName = item.sourceAppName {
                            existingItem.sourceAppName = newAppName
                        }

                        isDuplicate = true
                        print("[Clipmighty] Deduplicated item: Updated timestamp for existing entry.")
                    }
                }

                if !isDuplicate {
                    context.insert(item)
                    print("[Clipmighty] Saved new clipboard item: \(item.content.prefix(50))...")
                }

                try? context.save()
            }
        }

        monitor.onHistoryItemCopied = { itemID in
            Task { @MainActor in
                let context = ModelContext(container)
                let descriptor = FetchDescriptor<ClipboardItem>(
                    predicate: #Predicate<ClipboardItem> { existing in
                        existing.id == itemID
                    }
                )

                if let existingItem = try? context.fetch(descriptor).first {
                    existingItem.timestamp = Date()
                    try? context.save()
                }
            }
        }

        // Apply user settings to the monitor
        // Default to true (ignore concealed content) if not explicitly set
        let ignoreConcealedDefault =
            UserDefaults.standard.object(forKey: "ignoreConcealedContent") == nil
            ? true : UserDefaults.standard.bool(forKey: "ignoreConcealedContent")
        monitor.ignoreConcealedContent = ignoreConcealedDefault

        // Load excluded apps from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "excludedApps"),
           let apps = try? JSONDecoder().decode([ExcludedApp].self, from: data) {
            monitor.denylistedBundleIDs = Set(apps.map(\.bundleID))
            print("[Clipmighty] Loaded \(apps.count) excluded apps")
        } else {
            // Add default exclusions
            monitor.denylistedBundleIDs.insert("com.apple.keychainaccess")
            print("[Clipmighty] Using default excluded apps")
        }

        // Start monitoring on launch
        monitor.startMonitoring()
        print("[Clipmighty] Clipboard monitoring initialized and callback connected")
    }

    @MainActor
    static func purgeOldItems(context: ModelContext) {
        // Migration: Check if we have the new "retentionDuration" key
        if UserDefaults.standard.object(forKey: "retentionDuration") == nil {
            // Check for legacy key
            if let legacyDays = UserDefaults.standard.object(forKey: "clipboardHistoryRetentionDays") as? Int {
                // Migrate legacy value to seconds
                let seconds = legacyDays == 0 ? 0 : legacyDays * 86400
                UserDefaults.standard.set(seconds, forKey: "retentionDuration")
                // Remove legacy key after successful migration
                UserDefaults.standard.removeObject(forKey: "clipboardHistoryRetentionDays")
                print("[Clipmighty] Migrated legacy retention setting: \(legacyDays) days -> \(seconds) seconds")
            } else {
                // specific default: 7 days (604800 seconds)
                UserDefaults.standard.set(604800, forKey: "retentionDuration")
            }
        }

        let retentionDuration = UserDefaults.standard.integer(forKey: "retentionDuration")

        // 0 means keep forever
        guard retentionDuration > 0 else { return }

        let cutoffDate = Date().addingTimeInterval(-Double(retentionDuration))

        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate { $0.timestamp < cutoffDate })

        do {
            let oldItems = try context.fetch(descriptor)
            var deletedCount = 0
            for item in oldItems where !item.isPinned {
                context.delete(item)
                deletedCount += 1
            }

            if deletedCount > 0 {
                try context.save()
                print("[Clipmighty] Purged \(deletedCount) old clipboard items (clean up < \(cutoffDate))")
            }
        } catch {
            print("Purge failed: \(error)")
        }
    }
}
