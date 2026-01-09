//
//  KeyboardShortcutRecorder.swift
//  Clipmighty
//
//  A SwiftUI view for recording and validating keyboard shortcuts.
//

import AppKit
import Carbon
import SwiftUI

struct KeyboardShortcutRecorder: NSViewRepresentable {
    @Binding var keyCode: Int
    @Binding var modifierFlags: Int

    func makeNSView(context: Context) -> KeyRecorderView {
        let view = KeyRecorderView()
        view.onShortcutRecorded = { keyCode, modifiers in
            self.keyCode = keyCode
            self.modifierFlags = modifiers

            // Save to UserDefaults
            UserDefaults.standard.set(keyCode, forKey: "overlayShortcutKeyCode")
            UserDefaults.standard.set(modifiers, forKey: "overlayShortcutModifiers")
        }
        return view
    }

    func updateNSView(_ nsView: KeyRecorderView, context: Context) {
        nsView.displayKeyCode = keyCode
        nsView.displayModifiers = modifierFlags
    }
}

class KeyRecorderView: NSView {
    var onShortcutRecorded: ((Int, Int) -> Void)?
    var displayKeyCode: Int = KeyCode.vKey {
        didSet { needsDisplay = true }
    }
    var displayModifiers: Int = controlKey {
        didSet { needsDisplay = true }
    }

    private var isRecording = false
    private var localEventMonitor: Any?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(startRecording))
        addGestureRecognizer(clickGesture)
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: 200, height: 30)
    }

    @objc private func startRecording() {
        isRecording = true
        layer?.borderColor = NSColor.controlAccentColor.cgColor
        needsDisplay = true

        // Install local event monitor to capture keyDown events
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
            return nil // Consume the event
        }

        // Make this view first responder
        window?.makeFirstResponder(self)
    }

    private func handleKeyDown(_ event: NSEvent) {
        guard isRecording else { return }

        let keyCode = Int(event.keyCode)
        let modifierFlags = event.modifierFlags

        // Convert NSEvent modifiers to Carbon modifiers
        var carbonModifiers = 0
        if modifierFlags.contains(.command) {
            carbonModifiers |= cmdKey
        }
        if modifierFlags.contains(.shift) {
            carbonModifiers |= shiftKey
        }
        if modifierFlags.contains(.option) {
            carbonModifiers |= optionKey
        }
        if modifierFlags.contains(.control) {
            carbonModifiers |= controlKey
        }

        // Validate the shortcut
        guard let error = validateShortcut(keyCode: keyCode, modifiers: carbonModifiers) else {
            // Valid shortcut - record it
            displayKeyCode = keyCode
            displayModifiers = carbonModifiers
            onShortcutRecorded?(keyCode, carbonModifiers)
            stopRecording()
            return
        }

        // Show error
        showValidationError(error)
        stopRecording()
    }

    private func stopRecording() {
        isRecording = false
        layer?.borderColor = NSColor.separatorColor.cgColor
        needsDisplay = true

        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }

    private func validateShortcut(keyCode: Int, modifiers: Int) -> String? {
        // Require at least one modifier key
        if modifiers == 0 {
            return "Please use at least one modifier key (⌘, ⇧, ⌥, or ⌃)"
        }

        // Check for common system shortcuts to avoid conflicts
        let conflicts = SystemShortcuts.conflicts(keyCode: keyCode, modifiers: modifiers)
        if !conflicts.isEmpty {
            return "Conflicts with system shortcut: \(conflicts.joined(separator: ", "))"
        }

        return nil
    }

    private func showValidationError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Invalid Shortcut"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let displayString: String
        if isRecording {
            displayString = "Press shortcut..."
        } else {
            displayString = KeyboardShortcutFormatter.format(keyCode: displayKeyCode, modifiers: displayModifiers)
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: isRecording ? NSColor.controlAccentColor : NSColor.labelColor
        ]

        let string = NSAttributedString(string: displayString, attributes: attributes)
        let stringSize = string.size()
        let stringRect = NSRect(
            x: (bounds.width - stringSize.width) / 2,
            y: (bounds.height - stringSize.height) / 2,
            width: stringSize.width,
            height: stringSize.height
        )

        string.draw(in: stringRect)
    }

    override var acceptsFirstResponder: Bool {
        return true
    }
}

// MARK: - Keyboard Shortcut Formatter

struct KeyboardShortcutFormatter {
    static func format(keyCode: Int, modifiers: Int) -> String {
        var parts: [String] = []

        // Add modifier symbols in standard order
        if modifiers & controlKey != 0 {
            parts.append("⌃")
        }
        if modifiers & optionKey != 0 {
            parts.append("⌥")
        }
        if modifiers & shiftKey != 0 {
            parts.append("⇧")
        }
        if modifiers & cmdKey != 0 {
            parts.append("⌘")
        }

        // Add key character
        if let keyName = keyCodeToString(keyCode) {
            parts.append(keyName)
        }

        return parts.joined()
    }

    private static func keyCodeToString(_ keyCode: Int) -> String? {
        // Check letter keys first
        if let letter = letterKeyToString(keyCode) {
            return letter
        }
        // Check number keys
        if let number = numberKeyToString(keyCode) {
            return number
        }
        // Check symbol keys
        if let symbol = symbolKeyToString(keyCode) {
            return symbol
        }
        // Check special keys
        return specialKeyToString(keyCode)
    }

    // swiftlint:disable:next cyclomatic_complexity
    private static func letterKeyToString(_ keyCode: Int) -> String? {
        switch keyCode {
        case 0x00: return "A"
        case 0x01: return "S"
        case 0x02: return "D"
        case 0x03: return "F"
        case 0x04: return "H"
        case 0x05: return "G"
        case 0x06: return "Z"
        case 0x07: return "X"
        case 0x08: return "C"
        case 0x09: return "V"
        case 0x0B: return "B"
        case 0x0C: return "Q"
        case 0x0D: return "W"
        case 0x0E: return "E"
        case 0x0F: return "R"
        case 0x10: return "Y"
        case 0x11: return "T"
        case 0x25: return "L"
        case 0x26: return "J"
        case 0x28: return "K"
        case 0x2D: return "N"
        case 0x2E: return "M"
        case 0x1F: return "O"
        case 0x20: return "U"
        case 0x22: return "I"
        case 0x23: return "P"
        default: return nil
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private static func numberKeyToString(_ keyCode: Int) -> String? {
        switch keyCode {
        case 0x12: return "1"
        case 0x13: return "2"
        case 0x14: return "3"
        case 0x15: return "4"
        case 0x17: return "5"
        case 0x16: return "6"
        case 0x1A: return "7"
        case 0x1C: return "8"
        case 0x19: return "9"
        case 0x1D: return "0"
        default: return nil
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private static func symbolKeyToString(_ keyCode: Int) -> String? {
        switch keyCode {
        case 0x18: return "="
        case 0x1B: return "-"
        case 0x1E: return "]"
        case 0x21: return "["
        case 0x27: return "'"
        case 0x29: return ";"
        case 0x2A: return "\\"
        case 0x2B: return ","
        case 0x2C: return "/"
        case 0x2F: return "."
        case 0x32: return "`"
        default: return nil
        }
    }

    private static func specialKeyToString(_ keyCode: Int) -> String? {
        switch keyCode {
        case 0x24: return "↩"
        case 0x30: return "⇥"
        case 0x31: return "Space"
        case 0x33: return "⌫"
        case 0x35: return "⎋"
        case 0x7B: return "←"
        case 0x7C: return "→"
        case 0x7D: return "↓"
        case 0x7E: return "↑"
        default: return nil
        }
    }
}

// MARK: - System Shortcuts Validator

struct SystemShortcuts {
    struct SystemShortcut {
        let keyCode: Int
        let modifiers: Int
        let description: String
    }

    /// Returns a list of conflicting system shortcuts for the given key combination
    static func conflicts(keyCode: Int, modifiers: Int) -> [String] {
        var conflicts: [String] = []

        // Common system shortcuts to check
        let systemShortcuts: [SystemShortcut] = [
            SystemShortcut(keyCode: 0x0C, modifiers: cmdKey, description: "⌘Q - Quit Application"),
            SystemShortcut(keyCode: 0x0D, modifiers: cmdKey, description: "⌘W - Close Window"),
            SystemShortcut(keyCode: 0x2E, modifiers: cmdKey, description: "⌘M - Minimize Window"),
            SystemShortcut(keyCode: 0x04, modifiers: cmdKey, description: "⌘H - Hide Application"),
            SystemShortcut(keyCode: 0x2B, modifiers: cmdKey, description: "⌘, - Preferences"),
            SystemShortcut(keyCode: 0x00, modifiers: cmdKey, description: "⌘A - Select All"),
            SystemShortcut(keyCode: 0x08, modifiers: cmdKey, description: "⌘C - Copy"),
            SystemShortcut(keyCode: 0x07, modifiers: cmdKey, description: "⌘X - Cut"),
            SystemShortcut(keyCode: 0x09, modifiers: cmdKey, description: "⌘V - Paste"),
            SystemShortcut(keyCode: 0x06, modifiers: cmdKey, description: "⌘Z - Undo"),
            SystemShortcut(keyCode: 0x31, modifiers: cmdKey, description: "⌘Space - Spotlight"),
            SystemShortcut(keyCode: 0x30, modifiers: cmdKey, description: "⌘Tab - Switch Apps"),
            SystemShortcut(keyCode: 0x31, modifiers: cmdKey | controlKey, description: "⌃⌘Space - Emoji & Symbols")
        ]

        for shortcut in systemShortcuts {
            if keyCode == shortcut.keyCode && modifiers == shortcut.modifiers {
                conflicts.append(shortcut.description)
            }
        }

        return conflicts
    }
}
