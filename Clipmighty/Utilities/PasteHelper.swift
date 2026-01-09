import Cocoa
import ApplicationServices

class PasteHelper {

    static func canPaste() -> Bool {
        return AXIsProcessTrusted()
    }

    static func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    static func paste() {
        guard AXIsProcessTrusted() else {
            print("[PasteHelper] Accessibility permission denied. Cannot paste.")
            return
        }

        let source = CGEventSource(stateID: .hidSystemState)
        // kVK_ANSI_V = 0x09
        let vCode: CGKeyCode = 0x09

        guard let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: vCode, keyDown: true),
              let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: vCode, keyDown: false) else {
            return
        }

        // Emulate Command key modifier
        cmdDown.flags = .maskCommand
        cmdUp.flags = .maskCommand

        // Post events
        cmdDown.post(tap: .cghidEventTap)
        cmdUp.post(tap: .cghidEventTap)
    }
}
