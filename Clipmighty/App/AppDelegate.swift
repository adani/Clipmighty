import AppKit
import Carbon
import SwiftData
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var settingsWindow: NSWindow?
    static var isForceQuit: Bool = false
    
    // Reference to clipboard monitor
    var clipboardMonitor: ClipboardMonitor?

    // Overlay Components
    var overlayWindow: OverlayWindow?
    var overlayViewModel: OverlayViewModel?
    var localEventMonitor: Any?
    var globalMouseMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Listen for Force Quit notifications from newer instances
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleForceQuit),
            name: Notification.Name("com.clipmighty.forceQuit"),
            object: nil
        )

        // 1. Single Instance Check
        checkSingleInstance()

        // 2. Initial State: Accessory (Status Bar only)
        // LSUIElement is true in Info.plist, so it starts as .accessory by default usually,
        // but ensuring it here doesn't hurt, or we toggle it later.
        NSApp.setActivationPolicy(.accessory)

        // Observe window events to handle Settings window closing
        NotificationCenter.default.addObserver(
            self, selector: #selector(windowWillClose(_:)), name: NSWindow.willCloseNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self, selector: #selector(windowDidBecomeKey(_:)),
            name: NSWindow.didBecomeKeyNotification, object: nil)

        // 3. Setup Overlay
        setupOverlay()

        // 4. Setup Global Hotkey
        setupHotKey()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // If force quit (e.g. restart or single instance replacement), quit immediately
        if AppDelegate.isForceQuit {
            return .terminateNow
        }

        // If policy is regular (Dock icon visible), which usually means Settings is open
        // or user forcefully activated it, ask for confirmation.
        if NSApp.activationPolicy() == .regular {
            let alert = NSAlert()
            alert.messageText = "Quit Clipmighty?"
            alert.informativeText =
                "Are you sure you want to quit the application? It will stop monitoring your clipboard."
            alert.addButton(withTitle: "Quit")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                return .terminateNow
            } else {
                return .terminateCancel
            }
        }

        // If running in background/accessory mode, just quit (e.g. from Status Bar menu)
        return .terminateNow
    }

    private func checkSingleInstance() {
        let bundleID = Bundle.main.bundleIdentifier!
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)

        // If there are multiple instances, kill the *other* ones so this one can take over.
        // This supports the "Replace old instance" flow (e.g. from Xcode or Restart).
        if runningApps.count > 1 {
            // 1. Polite request via Distributed Notification (bypasses dialogs if app logic is correct)
            DistributedNotificationCenter.default().postNotificationName(
                Notification.Name("com.clipmighty.forceQuit"),
                object: nil
            )

            // 2. Fallback Mechanism
            for app in runningApps where app != NSRunningApplication.current {
                // Try to force terminate the old instance to avoid confirmation dialogs
                if !app.forceTerminate() {
                    app.terminate()
                }
            }
        }
    }

    @objc func handleForceQuit() {
        print("Received force quit request from another instance.")
        AppDelegate.isForceQuit = true
        NSApp.terminate(nil)
    }

    // MARK: - Overlay Management

    func setupOverlay() {
        let viewModel = OverlayViewModel()
        viewModel.modelContext = ModelContext(ClipmightyApp.sharedModelContainer)
        self.overlayViewModel = viewModel

        // Create hosting controller
        // OverlayView expects bindable viewModel
        let overlayView = OverlayView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: overlayView)
        hostingController.identifier = NSUserInterfaceItemIdentifier("OverlayContent")
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor

        let window = OverlayWindow()
        window.contentViewController = hostingController
        
        // Set up key event handler for the window
        window.keyEventHandler = { [weak self] event in
            return self?.handleWindowKeyDown(event) ?? false
        }
        
        self.overlayWindow = window

        // Monitor local events for navigation only when window is key to avoid interfering globally
        // This is safe because we use a local monitor, not global.
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            return self?.handleLocalKeyDown(event) ?? event
        }

        // Monitor global mouse clicks to dismiss overlay when clicking outside
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [
            .leftMouseDown, .rightMouseDown
        ]) { [weak self] _ in
            guard let self = self,
                  let window = self.overlayWindow,
                  window.isVisible else { return }
            
            // Get the current mouse location in screen coordinates
            let clickInScreen = NSEvent.mouseLocation
            let windowFrame = window.frame
            
            // If click is outside window frame, dismiss overlay
            if !windowFrame.contains(clickInScreen) {
                self.closeOverlay()
            }
        }
    }

    func setupHotKey() {
        // Load and register hotkey from preferences (or use default)
        HotKeyManager.shared.reloadFromPreferences()
        HotKeyManager.shared.onHotKeyTriggered = { [weak self] in
            self?.toggleOverlay()
        }
        
        // Listen for shortcut changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadHotKey),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    @objc private func reloadHotKey() {
        // Reload the hotkey when user defaults change
        HotKeyManager.shared.reloadFromPreferences()
        HotKeyManager.shared.onHotKeyTriggered = { [weak self] in
            self?.toggleOverlay()
        }
    }

    func toggleOverlay() {
        guard let window = overlayWindow else { return }

        if window.isVisible {
            closeOverlay()
        } else {
            showOverlay()
        }
    }

    func showOverlay() {
        guard let window = overlayWindow, let viewModel = overlayViewModel else { return }

        viewModel.loadItems()

        // Center on the screen where mouse is before showing
        window.centerOnActiveScreen()

        // Use orderFrontRegardless() to bring the panel to front without activating the app.
        // Since OverlayWindow is an NSPanel with .nonactivatingPanel style, it can become key
        // without requiring NSApp.activate(), which would also bring other windows forward.
        window.orderFrontRegardless()
        window.makeKey()
    }

    func closeOverlay() {
        overlayWindow?.orderOut(nil)
        overlayViewModel?.reset()
        // Since we use nonactivatingPanel, we don't need to hide the app.
        // The previous app should already have focus. If the settings window
        // is open, it will remain visible and accessible.
    }

    func handleLocalKeyDown(_ event: NSEvent) -> NSEvent? {
        print("[AppDelegate] handleLocalKeyDown called - keyCode: \(event.keyCode)")
        // Only handle if overlay is visible and key
        guard let window = overlayWindow, window.isVisible, window.isKeyWindow else { 
            print("[AppDelegate] handleLocalKeyDown - overlay not visible/key, passing event")
            return event 
        }
        
        // Let events pass through to the window's keyDown handler
        // The window handler is more effective at preventing system beeps
        print("[AppDelegate] Passing event to window handler")
        return event
    }
    
    func handleWindowKeyDown(_ event: NSEvent) -> Bool {
        print("[AppDelegate] handleWindowKeyDown called - keyCode: \(event.keyCode)")
        // Only handle if overlay is visible and key
        guard let window = overlayWindow, window.isVisible else { 
            print("[AppDelegate] handleWindowKeyDown - overlay not visible")
            return false 
        }
        guard let viewModel = overlayViewModel else { 
            print("[AppDelegate] handleWindowKeyDown - no viewModel")
            return false 
        }

        print("[AppDelegate] Processing window key event")
        switch event.keyCode {
        case 126:  // Up Arrow
            print("[AppDelegate] Up arrow in window handler")
            viewModel.moveSelectionUp()
            return true  // Event handled
        case 125:  // Down Arrow
            print("[AppDelegate] Down arrow in window handler")
            viewModel.moveSelectionDown()
            return true  // Event handled
        case 36:  // Enter/Return
            print("[AppDelegate] Enter in window handler - pasting")
            if let item = viewModel.getSelectedItem() {
                pasteItem(item)
            }
            return true  // Event handled - prevents beep
        default:
            print("[AppDelegate] Other key in window handler (\(event.keyCode)) - closing")
            // Any other key dismisses the overlay
            closeOverlay()
            return true  // Event handled
        }
    }

    func pasteItem(_ item: ClipboardItem) {
        // 1. Flag clipboard monitor to skip the next change
        clipboardMonitor?.skipNextChange = true

        // 2. Copy content to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)

        // 3. Hide window and app
        closeOverlay()

        // 4. Synthesize Paste (wait briefly for focus switch)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            PasteHelper.paste()
        }
    }

    // MARK: - Dock Icon Management

    func openSettings() {
        // Show Dock Icon so the new window has a place to live
        NSApp.setActivationPolicy(.regular)
        // Activation will happen in windowDidBecomeKey when the window actually appears
    }

    @objc func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        // Ignore OverlayWindow completely - it manages its own visibility
        if window is OverlayWindow { return }
        
        // Ignore if the overlay is currently visible - don't interfere with overlay presentation
        if overlayWindow?.isVisible == true { return }
        
        // Only handle normal-level windows (Settings window)
        // SwiftUI Settings windows have .normal level
        guard window.level == .normal else { return }
        
        // Track settings window reference
        self.settingsWindow = window
        
        // Only switch to regular activation policy if not already set
        // This shows the Dock icon when settings window is open
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
            
            // Only activate and bring to front when initially showing settings
            // (when activation policy was changed)
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    @objc func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == self.settingsWindow {
            // Settings closing, hide Dock icon
            // Wait a tick to ensure animation finishes or window is gone
            DispatchQueue.main.async {
                // Only hide if no other visible windows require Dock?
                // For this app, Settings is likely the only main window.
                NSApp.setActivationPolicy(.accessory)
                self.settingsWindow = nil
            }
        }
    }
}
