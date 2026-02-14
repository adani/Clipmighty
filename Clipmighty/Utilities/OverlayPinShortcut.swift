import AppKit
import Carbon

struct OverlayPinShortcut {
    static let keyCodeDefaultsKey = "pinUnpinShortcutKeyCode"
    static let modifiersDefaultsKey = "pinUnpinShortcutModifiers"

    static let defaultKeyCode: Int = 36
    static let defaultModifiers: Int = shiftKey

    static func loadFromDefaults() -> (keyCode: Int, modifiers: Int) {
        let defaults = UserDefaults.standard

        let keyCode = (defaults.object(forKey: keyCodeDefaultsKey) as? Int) ?? defaultKeyCode
        let modifiers = (defaults.object(forKey: modifiersDefaultsKey) as? Int) ?? defaultModifiers

        return (keyCode, modifiers)
    }

    static func formattedShortcut() -> String {
        let shortcut = loadFromDefaults()
        return KeyboardShortcutFormatter.format(
            keyCode: shortcut.keyCode,
            modifiers: shortcut.modifiers
        )
    }

    static func matches(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> Bool {
        let shortcut = loadFromDefaults()
        return Int(keyCode) == shortcut.keyCode && carbonModifiers(from: modifiers) == shortcut.modifiers
    }

    static func carbonModifiers(from modifiers: NSEvent.ModifierFlags) -> Int {
        let normalized = modifiers.intersection(.deviceIndependentFlagsMask)

        var carbonModifiers = 0
        if normalized.contains(.command) {
            carbonModifiers |= cmdKey
        }
        if normalized.contains(.shift) {
            carbonModifiers |= shiftKey
        }
        if normalized.contains(.option) {
            carbonModifiers |= optionKey
        }
        if normalized.contains(.control) {
            carbonModifiers |= controlKey
        }

        return carbonModifiers
    }
}
