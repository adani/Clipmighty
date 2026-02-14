import AppKit
import SwiftUI

class ToastWindow: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 60), // Sized to fit content without ellipsizing
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        self.isFloatingPanel = true
        self.level = .floating

        // Transparent setup
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false

        // Pass clicks through
        self.ignoresMouseEvents = true

        // Behavior
        self.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        self.isMovable = false
    }

    // Helper to center and show
    func show(message: String = "Copied", symbolName: String = "checkmark.circle.fill", duration: TimeInterval = 1.5) {
        // Layout the content
        guard let screen = NSScreen.main else { return }

        // Create hosting controller if needed or ensuring view is fresh
        if self.contentViewController == nil {
            self.contentViewController = NSHostingController(
                rootView: ToastView(message: message, symbolName: symbolName)
            )
        } else {
            self.contentViewController = NSHostingController(
                rootView: ToastView(message: message, symbolName: symbolName)
            )
        }

        // Size to fit content
        if let view = self.contentView {
            let fittingSize = view.fittingSize
            let screenRect = screen.visibleFrame

            // Position: Center horizontally, slightly above bottom or center
            // Let's go with: Bottom third of the screen, looks like a nice notification
            let screenX = screenRect.midX - (fittingSize.width / 2)
            let screenY = screenRect.minY + 140 // 140px from bottom bezel

            self.setFrame(NSRect(origin: CGPoint(x: screenX, y: screenY), size: fittingSize), display: true)
        }

        self.alphaValue = 0
        self.orderFront(nil)

        // Animate In
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            self.animator().alphaValue = 1
        } completionHandler: {
            // Wait and Animate Out
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                guard let self = self else { return }
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.3
                    self.animator().alphaValue = 0
                } completionHandler: {
                    self.orderOut(nil)
                }
            }
        }
    }
}
