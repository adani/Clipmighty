//
//  ClipboardMonitor.swift
//  Clipmighty
//
//  Core clipboard monitoring functionality.
//  Power state detection in: ClipboardMonitor+PowerState.swift
//  Idle detection in: ClipboardMonitor+IdleDetection.swift
//  Clipboard operations in: ClipboardMonitor+Operations.swift
//

import AppKit
import Dispatch
import SwiftUI

// MARK: - Pasteboard Abstraction for Testing
protocol PasteboardReadable {
    var changeCount: Int { get }
    var types: [NSPasteboard.PasteboardType]? { get }
    func string(forType dataType: NSPasteboard.PasteboardType) -> String?
    func data(forType dataType: NSPasteboard.PasteboardType) -> Data?
    func readObjects(forClasses classArray: [AnyClass], options: [NSPasteboard.ReadingOptionKey: Any]?) -> [Any]?
    
    // Write methods (Mocking write is useful for verification too)
    @discardableResult func clearContents() -> Int
    func writeObjects(_ objects: [NSPasteboardWriting]) -> Bool
    func setString(_ string: String, forType dataType: NSPasteboard.PasteboardType) -> Bool
    func setData(_ data: Data?, forType dataType: NSPasteboard.PasteboardType) -> Bool
}

extension NSPasteboard: PasteboardReadable {}

@Observable
class ClipboardMonitor {
    /// Using DispatchSourceTimer instead of Timer for better battery efficiency.
    /// DispatchSourceTimer with leeway allows the system to coalesce wake-ups,
    /// reducing CPU overhead compared to a strict Timer.
    var dispatchTimer: DispatchSourceTimer?
    private var idleCheckTimer: DispatchSourceTimer?

    // Internal so extensions can update it
    var lastChangeCount: Int = 0

    let pasteboard: PasteboardReadable

    /// Observer for power state changes
    private var powerStateObserver: NSObjectProtocol?

    /// Event monitor for immediate resume from idle (only active when paused)
    var activityEventMonitor: Any?

    /// Current power state for adaptive polling
    private(set) var currentPowerState: PowerState = .pluggedIn

    /// Whether monitoring is currently paused due to idle
    var isPausedForIdle: Bool = false

    /// Idle threshold in seconds (pause after this much inactivity)
    let idleThresholdSeconds: Double = 120  // 2 minutes

    /// How often to check for idle state (in seconds)
    private let idleCheckIntervalSeconds: Double = 60

    var currentContent: String?
    var lastSourceApp: String?

    // Simple allowlist/denylist for testing/MVP
    var denylistedBundleIDs: Set<String> = []
    var allowlistedBundleIDs: Set<String> = []

    /// Whether to ignore concealed/auto-generated clipboard content (from password managers)
    var ignoreConcealedContent: Bool = true

    /// Flag to skip the next clipboard change detection (e.g., when pasting from overlay)
    var skipNextChange: Bool = false

    // Callback to handling new item
    // Changed signature to pass the whole ClipboardItem object or params for it
    var onNewItem: ((ClipboardItem) -> Void)?

    // MARK: - Initialization

    // MARK: - Initialization

    init(pasteboard: PasteboardReadable = NSPasteboard.general) {
        self.pasteboard = pasteboard
        self.lastChangeCount = pasteboard.changeCount
        self.currentPowerState = Self.detectPowerState()

        // Observe settings changes for concealed content preference
        NotificationCenter.default.addObserver(
            forName: .ignoreConcealedContentChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let enabled = notification.userInfo?["enabled"] as? Bool {
                self?.ignoreConcealedContent = enabled
                print(
                    "[ClipboardMonitor] Password manager protection \(enabled ? "enabled" : "disabled")"
                )
            }
        }
    }

    // MARK: - Monitoring

    func startMonitoring() {
        // Stop any existing timers first
        stopMonitoring()

        // Detect current power state
        currentPowerState = Self.detectPowerState()
        isPausedForIdle = false

        // Set up power state change observers
        setupPowerStateObservers()

        // Start the clipboard timer with current power state settings
        startTimerWithCurrentPowerState()

        // Start idle detection timer
        startIdleCheckTimer()
    }

    private func startIdleCheckTimer() {
        idleCheckTimer?.cancel()

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(
            deadline: .now() + idleCheckIntervalSeconds,
            repeating: .seconds(Int(idleCheckIntervalSeconds)),
            leeway: .seconds(5)  // Very loose timing for idle checks
        )

        timer.setEventHandler { [weak self] in
            self?.checkIdleState()
        }

        idleCheckTimer = timer
        timer.resume()
    }

    private func setupPowerStateObservers() {
        // Remove existing observer if any
        if let observer = powerStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        // Observe Low Power Mode changes (macOS 12+)
        if #available(macOS 12.0, *) {
            powerStateObserver = NotificationCenter.default.addObserver(
                forName: .NSProcessInfoPowerStateDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handlePowerStateChange()
            }
        }

        // Also observe workspace notifications for power source changes
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Re-check power state after wake from sleep
            // Also resume from idle state since user just woke the machine
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Correctly resume from idle if needed (handles timer state)
                if self?.isPausedForIdle == true {
                    self?.resumeFromIdle()
                }

                self?.handlePowerStateChange()
                // Immediate clipboard check after wake
                self?.checkForChanges()
            }
        }
    }

    private func handlePowerStateChange() {
        let newPowerState = Self.detectPowerState()

        guard newPowerState != currentPowerState else { return }

        let oldState = currentPowerState
        currentPowerState = newPowerState

        print(
            "[ClipboardMonitor] Power state changed: \(oldState.rawValue) → \(newPowerState.rawValue)"
        )
        print(
            "[ClipboardMonitor] Adjusting polling interval to \(newPowerState.pollingInterval)s with \(newPowerState.leewayMs)ms leeway"
        )

        // Restart timer with new interval (only if not paused for idle)

        // SAFETY: If we are paused for idle, the timer is suspended.
        // We MUST resume a suspended timer before releasing/cancelling it to avoid a crash.
        if isPausedForIdle {
            dispatchTimer?.resume()
        }

        dispatchTimer?.cancel()
        startTimerWithCurrentPowerState()
    }

    private func startTimerWithCurrentPowerState() {
        let timer = DispatchSource.makeTimerSource(queue: .main)

        let interval = currentPowerState.pollingInterval
        let leeway = currentPowerState.leewayMs

        timer.schedule(
            deadline: .now() + 0.1,
            repeating: .milliseconds(Int(interval * 1000)),
            leeway: .milliseconds(leeway)
        )

        timer.setEventHandler { [weak self] in
            self?.checkForChanges()
        }

        self.dispatchTimer = timer
        timer.resume()

        // If we were paused for idle, suspend immediately
        if isPausedForIdle {
            timer.suspend()
        }

        print(
            "[ClipboardMonitor] Started monitoring (\(currentPowerState.rawValue): \(interval)s interval, \(leeway)ms leeway)"
        )
    }

    func stopMonitoring() {
        // Resume before canceling to avoid crash (can't cancel a suspended source)
        if isPausedForIdle {
            dispatchTimer?.resume()
        }

        dispatchTimer?.cancel()
        dispatchTimer = nil

        idleCheckTimer?.cancel()
        idleCheckTimer = nil

        // Clean up activity event monitor
        stopActivityEventMonitor()

        if let observer = powerStateObserver {
            NotificationCenter.default.removeObserver(observer)
            powerStateObserver = nil
        }

        isPausedForIdle = false
    }

    // MARK: - Change Detection

    func checkForChanges() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        // Skip this change if flagged (e.g., from overlay paste)
        if skipNextChange {
            print("[ClipboardMonitor] Skipping clipboard change (from overlay paste)")
            skipNextChange = false
            return
        }

        // Log all pasteboard types for debugging
        let types = pasteboard.types ?? []
        let typeStrings = types.map { $0.rawValue }
        print("[ClipboardMonitor] Clipboard changed. Pasteboard types: \(typeStrings)")

        // 1. Check for sensitive content
        if ignoreConcealedContent && isSensitiveClipboardContent() {
            print("[ClipboardMonitor] Ignoring concealed/auto-generated clipboard content")
            return
        }

        // Get content info
        let frontApp = NSWorkspace.shared.frontmostApplication
        let bundleID = frontApp?.bundleIdentifier
        let appName = frontApp?.localizedName

        // 2. Filter by App
        if let bundleID = bundleID {
            if !allowlistedBundleIDs.isEmpty && !allowlistedBundleIDs.contains(bundleID) { return }
            if denylistedBundleIDs.contains(bundleID) { return }
        }

        // Perform heavy lifting on a background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Re-read types on background thread (safe for NSPasteboard)
            let types = self.pasteboard.types ?? []

            if let item = self.createBestItem(from: types, bundleID: bundleID, appName: appName) {
                DispatchQueue.main.async {
                    self.currentContent = item.content
                    self.lastSourceApp = appName
                    self.onNewItem?(item)
                }
            }
        }
    }

    func updateLastChangeCount() {
        self.lastChangeCount = pasteboard.changeCount
    }

    // MARK: - Sensitive Content Detection

    /// Checks if the current clipboard content is marked as sensitive by password managers.
    private func isSensitiveClipboardContent() -> Bool {
        let types = pasteboard.types ?? []

        // Check for concealed type (used by 1Password, Bitwarden, etc.)
        if types.contains(.concealedType) {
            return true
        }

        // Check for auto-generated type (used for generated passwords)
        if types.contains(.autoGeneratedType) {
            return true
        }

        return false
    }
}
