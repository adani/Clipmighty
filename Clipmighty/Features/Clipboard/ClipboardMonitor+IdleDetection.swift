//
//  ClipboardMonitor+IdleDetection.swift
//  Clipmighty
//
//  Idle detection functionality for ClipboardMonitor to pause monitoring
//  when the user is inactive.
//

import AppKit
import Foundation
import Quartz

// MARK: - Idle Detection

extension ClipboardMonitor {

    /// Returns the number of seconds since the last user input (keyboard/mouse)
    func getIdleTimeSeconds() -> Double {
        // CGEventSource gives us system-wide idle time
        let idleTime = CGEventSource.secondsSinceLastEventType(
            .hidSystemState,
            eventType: .null  // .null checks all event types
        )
        return idleTime
    }

    /// Checks current idle state and pauses/resumes monitoring accordingly
    func checkIdleState() {
        let idleTime = getIdleTimeSeconds()
        let wasIdle = isPausedForIdle
        let isNowIdle = idleTime >= idleThresholdSeconds

        if isNowIdle && !wasIdle {
            // User became idle, pause clipboard monitoring
            pauseForIdle()
        } else if !isNowIdle && wasIdle {
            // User returned from idle, resume monitoring
            resumeFromIdle()
        }
    }

    /// Pauses clipboard monitoring when user becomes idle
    func pauseForIdle() {
        guard !isPausedForIdle else { return }

        isPausedForIdle = true
        dispatchTimer?.suspend()

        // Start monitoring for user activity to resume immediately
        startActivityEventMonitor()

        print("[ClipboardMonitor] User idle, pausing clipboard monitoring")
    }

    /// Resumes clipboard monitoring when user becomes active
    func resumeFromIdle() {
        guard isPausedForIdle else { return }

        isPausedForIdle = false

        // Stop the activity monitor (no longer needed)
        stopActivityEventMonitor()

        // Resume clipboard polling
        dispatchTimer?.resume()

        // Do an immediate check in case clipboard changed while idle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.checkForChanges()
        }

        print("[ClipboardMonitor] User active, resuming clipboard monitoring")
    }

    /// Starts monitoring for user activity (keyboard/mouse) to resume immediately from idle.
    /// This is more responsive than waiting for the idle check timer.
    func startActivityEventMonitor() {
        guard activityEventMonitor == nil else { return }

        // Monitor for any user input events
        let eventMask: NSEvent.EventTypeMask = [
            .keyDown, .keyUp,
            .mouseMoved, .leftMouseDown, .rightMouseDown,
            .scrollWheel, .leftMouseDragged, .rightMouseDragged
        ]

        activityEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] _ in
            // User is active! Resume immediately.
            DispatchQueue.main.async {
                self?.resumeFromIdle()
            }
        }

        print("[ClipboardMonitor] Started activity monitor for immediate resume")
    }

    /// Stops the activity event monitor
    func stopActivityEventMonitor() {
        if let monitor = activityEventMonitor {
            NSEvent.removeMonitor(monitor)
            activityEventMonitor = nil
        }
    }
}
