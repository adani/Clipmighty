import XCTest

final class HistoryListUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testClickItemCopiesToClipboard() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-enableTestMode"]
        app.launch()

        // Wait a bit for app to stabilize
        sleep(1)

        // Attempt to find the status item to open the menu
        // Status items in menu bar are often under the "MenuBar" menu of the app or system
        // For standard NSStatusItem, they appear in app.statusItems
        let statusItem = app.statusItems.firstMatch
        if statusItem.exists {
            statusItem.click()
        }
        
        // Wait for the window content to appear
        // We look for the mock data text "Hello, world!"
        // Using the newly added accessibility identifier and label
        let itemText = "Hello, world!"
        
        // Wait for the list to populate (give a generous timeout for async data)
        let predicate = NSPredicate(format: "identifier == 'ClipboardRow' AND label CONTAINS[c] %@", itemText)
        // Note: In some cases, the container might be the button/cell.
        // We search recursively.
        let element = app.descendants(matching: .any).matching(predicate).firstMatch
        
        if !element.waitForExistence(timeout: 10.0) {
             // Debugging help
             print(app.debugDescription)
             XCTFail("Could not find list item with text '\(itemText)'")
             return
        }
        
        element.click()
        
        // Verify Clipboard
        // Give it a moment to copy
        Thread.sleep(forTimeInterval: 1.0)
        
        let pasteboard = NSPasteboard.general
        let content = pasteboard.string(forType: .string)
        
        XCTAssertEqual(content, "Hello, world!", "Clipboard content should match the clicked item")
    }
}
