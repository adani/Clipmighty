import AppKit

extension AppDelegate {
    func handleOverlayNavigationKey(_ keyCode: UInt16, with viewModel: OverlayViewModel) -> Bool {
        let action: (() -> Void)?

        switch keyCode {
        case 126:  // Up Arrow
            action = {
                print("[AppDelegate] Up arrow in window handler")
                viewModel.moveSelectionUp()
            }
        case 125:  // Down Arrow
            action = {
                print("[AppDelegate] Down arrow in window handler")
                viewModel.moveSelectionDown()
            }
        case 116:  // Page Up
            action = {
                print("[AppDelegate] Page Up in window handler")
                viewModel.moveSelectionPageUp()
            }
        case 121:  // Page Down
            action = {
                print("[AppDelegate] Page Down in window handler")
                viewModel.moveSelectionPageDown()
            }
        case 115:  // Home
            action = {
                print("[AppDelegate] Home in window handler")
                viewModel.moveSelectionToFirst()
            }
        case 119:  // End
            action = {
                print("[AppDelegate] End in window handler")
                viewModel.moveSelectionToLast()
            }
        default:
            action = nil
        }

        guard let action else { return false }
        action()
        return true
    }

    func handleOverlayPasteKey(_ keyCode: UInt16, with viewModel: OverlayViewModel) -> Bool {
        guard keyCode == 36 || keyCode == 76 else { return false }

        print("[AppDelegate] Enter in window handler - pasting")
        if let item = viewModel.getSelectedItem() {
            pasteItem(item)
        }
        return true  // Event handled - prevents beep
    }

    func handleOverlayPinKey(_ event: NSEvent, with viewModel: OverlayViewModel) -> Bool {
        guard OverlayPinShortcut.matches(keyCode: event.keyCode, modifiers: event.modifierFlags) else {
            return false
        }

        print("[AppDelegate] Pin/unpin shortcut in window handler")
        let result = viewModel.togglePinForSelectedItem()
        if result == .pinned {
            showToast(message: "Pinned", symbolName: "pin.fill", duration: 0.8)
        }

        return result != .failed
    }
}
