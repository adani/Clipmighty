//
//  LaunchAtLoginService.swift
//  Clipmighty
//
//  Service to manage Login Item status using SMAppService (macOS 13+).
//

import Foundation
import ServiceManagement

/// A utility to register/unregister Clipmighty as a login item.
enum LaunchAtLoginService {
    /// The SMAppService instance for the main app bundle.
    private static var service: SMAppService {
        SMAppService.mainApp
    }

    /// Whether the app is currently registered to launch at login.
    static var isEnabled: Bool {
        get {
            service.status == .enabled
        }
        set {
            do {
                if newValue {
                    try service.register()
                    print("[Clipmighty] Successfully registered as login item.")
                } else {
                    try service.unregister()
                    print("[Clipmighty] Successfully unregistered from login items.")
                }
            } catch {
                print("[Clipmighty] Failed to update login item status: \(error.localizedDescription)")
            }
        }
    }

    /// Enables launch at login if this is the first launch.
    /// Call this once at app startup.
    static func enableOnFirstLaunchIfNeeded() {
        let hasLaunchedBeforeKey = "hasLaunchedBefore"
        if !UserDefaults.standard.bool(forKey: hasLaunchedBeforeKey) {
            isEnabled = true
            UserDefaults.standard.set(true, forKey: hasLaunchedBeforeKey)
            print("[Clipmighty] First launch detected. 'Launch at Login' enabled by default.")
        }
    }
}
