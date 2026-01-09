//
//  OnboardingWindow.swift
//  Clipmighty
//
//  Created on 2026-01-09.
//

import AppKit
import SwiftUI

/// Window controller for the onboarding experience
class OnboardingWindowController: NSObject {
    private var window: NSWindow?
    private var onComplete: (() -> Void)?

    /// Show the onboarding window
    func showOnboarding(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete

        let viewModel = OnboardingViewModel()
        let onboardingView = OnboardingView(viewModel: viewModel) { [weak self] in
            self?.closeOnboarding()
        }

        // Create the hosting controller
        let hostingController = NSHostingController(rootView: onboardingView)

        // Create a visually appealing window
        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor.windowBackgroundColor
        window.isOpaque = true
        window.hasShadow = true

        // Center on screen
        window.center()

        // Set minimum size
        window.minSize = NSSize(width: 600, height: 600)
        window.setContentSize(NSSize(width: 600, height: 600))

        // Make it appear above other windows
        window.level = .floating

        // Store reference
        self.window = window

        // Show the window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Close the onboarding window
    private func closeOnboarding() {
        window?.close()
        window = nil
        onComplete?()
    }
}
