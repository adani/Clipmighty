//
//  ClipboardMonitor+PowerState.swift
//  Clipmighty
//
//  Power state detection and adaptive polling for ClipboardMonitor.
//

import Foundation
import IOKit.ps

// MARK: - Power State

extension ClipboardMonitor {

    /// Power state enumeration for adaptive polling
    enum PowerState: String {
        case pluggedIn = "AC Power"
        case onBattery = "Battery"
        case lowPowerMode = "Low Power Mode"

        /// Polling interval in seconds based on power state
        var pollingInterval: Double {
            switch self {
            case .pluggedIn: return 1.0  // Fast polling when plugged in
            case .onBattery: return 2.0  // Balanced polling on battery
            case .lowPowerMode: return 3.0  // Conservative polling in low power mode
            }
        }

        /// Leeway in milliseconds for timer coalescing
        var leewayMs: Int {
            switch self {
            case .pluggedIn: return 300  // Tighter timing when on power
            case .onBattery: return 500  // More flexibility on battery
            case .lowPowerMode: return 1000  // Maximum flexibility in low power
            }
        }
    }
}

// MARK: - Power State Detection

extension ClipboardMonitor {

    /// Detects current power state: plugged in, on battery, or low power mode
    static func detectPowerState() -> PowerState {
        // Check for Low Power Mode first (macOS 12+)
        if #available(macOS 12.0, *) {
            if ProcessInfo.processInfo.isLowPowerModeEnabled {
                return .lowPowerMode
            }
        }

        // Check if on battery using IOKit
        if isOnBatteryPower() {
            return .onBattery
        }

        return .pluggedIn
    }

    /// Uses IOKit to check if the Mac is running on battery power
    static func isOnBatteryPower() -> Bool {
        let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef]

        guard let sources = sources, !sources.isEmpty else {
            // No battery sources found, assume plugged in (desktop Mac)
            return false
        }

        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source)?
                .takeUnretainedValue() as? [String: Any] {
                // Check power source state
                if let powerSourceState = description[kIOPSPowerSourceStateKey as String] as? String {
                    if powerSourceState == kIOPSBatteryPowerValue as String {
                        return true
                    }
                }
            }
        }

        return false
    }
}
