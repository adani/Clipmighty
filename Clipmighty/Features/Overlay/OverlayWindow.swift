import Cocoa
import SwiftUI

class OverlayWindow: NSPanel {
    // Closure to handle key events, returns true if event was handled
    var keyEventHandler: ((NSEvent) -> Bool)?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 450),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = false

        // Ensure it appears on all spaces and doesn't stick around
        self.collectionBehavior = [.canJoinAllSpaces, .transient]
    }

    /// Centers the window on the screen that currently contains the mouse cursor.
    func centerOnActiveScreen() {
        // Find the screen containing the mouse
        let mouseLocation = NSEvent.mouseLocation
        let activeScreen = NSScreen.screens.first { $0.frame.contains(mouseLocation) }
            ?? NSScreen.main ?? NSScreen.screens.first

        guard let screen = activeScreen else {
            self.center()
            return
        }

        let screenFrame = screen.visibleFrame
        let windowFrame = self.frame

        let newOriginX = screenFrame.origin.x + (screenFrame.width - windowFrame.width) / 2
        let newOriginY = screenFrame.origin.y + (screenFrame.height - windowFrame.height) / 2

        self.setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }

    // Override keyDown to handle events and prevent system beep
    override func keyDown(with event: NSEvent) {
        print("[OverlayWindow] keyDown - keyCode: \(event.keyCode), characters: \(event.characters ?? "nil")")

        // Try to handle with the custom handler first
        if let handler = keyEventHandler, handler(event) {
            print("[OverlayWindow] Event handled by keyEventHandler")
            return // Event was handled, prevent further processing and beep
        }

        // If not handled, pass to super (but this will likely beep for unhandled keys)
        print("[OverlayWindow] Event not handled, passing to super")
        super.keyDown(with: event)
    }
}
