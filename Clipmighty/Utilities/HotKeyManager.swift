import Carbon
import Cocoa

class HotKeyManager {
    static let shared = HotKeyManager()

    private var hotKeyID: UInt32 = 1
    private var eventHandler: EventHandlerRef?
    private var currentHotKeyRef: EventHotKeyRef?

    var onHotKeyTriggered: (() -> Void)?

    private init() {}

    func registerHotKey(keyCode: Int, modifiers: Int) {
        // Unregister existing hotkey first
        unregisterAll()
        
        // Simple fixed ID for now
        let hotKeyID = EventHotKeyID(signature: OSType(0x434C_4950), id: 1)  // "CLIP", 1

        var eventHotKey: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            UInt32(modifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &eventHotKey
        )

        if status != noErr {
            print("[HotKeyManager] Failed to register hotkey: \(status)")
            return
        }

        currentHotKeyRef = eventHotKey
        installEventHandler()
        
        let shortcutDisplay = KeyboardShortcutFormatter.format(keyCode: keyCode, modifiers: modifiers)
        print("[HotKeyManager] Registered global hotkey: \(shortcutDisplay)")
    }
    
    func reloadFromPreferences() {
        let keyCode = UserDefaults.standard.integer(forKey: "overlayShortcutKeyCode")
        let modifiers = UserDefaults.standard.integer(forKey: "overlayShortcutModifiers")
        
        // Use defaults if not set
        let finalKeyCode = keyCode != 0 ? keyCode : KeyCode.vKey
        let finalModifiers = modifiers != 0 ? modifiers : controlKey
        
        registerHotKey(keyCode: finalKeyCode, modifiers: finalModifiers)
    }

    private func installEventHandler() {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, _, userData) -> OSStatus in
                // Recover the manager instance
                guard let userData = userData else { return noErr }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()

                manager.handleHotKey()
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandler
        )
    }

    private func handleHotKey() {
        DispatchQueue.main.async { [weak self] in
            self?.onHotKeyTriggered?()
        }
    }

    func unregisterAll() {
        // Unregister the current hotkey if it exists
        if let hotKeyRef = currentHotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            currentHotKeyRef = nil
        }
        
        // Remove the event handler
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }
}

// Helper for key codes
enum KeyCode {
    static let vKey = 0x09
}
