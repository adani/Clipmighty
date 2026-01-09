import XCTest
import AppKit
@testable import Clipmighty

// MARK: - Mock Implementation

class MockPasteboard: PasteboardReadable {
    var changeCount: Int = 0
    var types: [NSPasteboard.PasteboardType]? = []
    
    var dataStore: [NSPasteboard.PasteboardType: Any] = [:]
    
    func string(forType dataType: NSPasteboard.PasteboardType) -> String? {
        return dataStore[dataType] as? String
    }
    
    func data(forType dataType: NSPasteboard.PasteboardType) -> Data? {
        return dataStore[dataType] as? Data
    }
    
    func readObjects(forClasses classArray: [AnyClass], options: [NSPasteboard.ReadingOptionKey : Any]?) -> [Any]? {
        // Simple mock support for specific types we test
        if classArray.contains(where: { $0 === NSColor.self }), let color = dataStore[.color] {
            return [color]
        }
        if classArray.contains(where: { $0 === NSImage.self }), let image = dataStore[NSPasteboard.PasteboardType("public.png")] {
             // For image, we might store dummy NSImage or handle it differently.
             // For logic tests avoiding UI classes like NSImage is often better if possible, but here we need it.
             return [image]
        }
        if classArray.contains(where: { $0 === NSURL.self }), let url = dataStore[.fileURL] {
            return [url]
        }
        return nil
    }
    
    // Writers updates the store and increments change count
    
    func clearContents() -> Int {
        dataStore.removeAll()
        types = []
        changeCount += 1
        return changeCount
    }
    
    func writeObjects(_ objects: [NSPasteboardWriting]) -> Bool {
        changeCount += 1
        for obj in objects {
            if let str = obj as? String {
                setString(str, forType: .string)
            } else if let color = obj as? NSColor {
                dataStore[.color] = color
                types?.append(.color)
            } else if let url = obj as? NSURL {
                 dataStore[.fileURL] = url
                 types?.append(.fileURL)
            }
        }
        return true
    }
    
    func setString(_ string: String, forType dataType: NSPasteboard.PasteboardType) -> Bool {
        dataStore[dataType] = string
        if types?.contains(dataType) == false {
            types?.append(dataType)
        }
        changeCount += 1
        return true
    }
    
    func setData(_ data: Data?, forType dataType: NSPasteboard.PasteboardType) -> Bool {
        dataStore[dataType] = data
        if let d = data {
             if types?.contains(dataType) == false {
                 types?.append(dataType)
            }
        }
        changeCount += 1
        return true
    }
    
    // Helper for tests to setup state directly
    func simulateExternalChange() {
        changeCount += 1
    }
}

// MARK: - Tests

final class ClipboardMonitorTests: XCTestCase {
    
    var monitor: ClipboardMonitor!
    var mockPasteboard: MockPasteboard!
    
    override func setUp() {
        super.setUp()
        mockPasteboard = MockPasteboard()
        // Initialize monitor with mock. Note: We do NOT start the timer (startMonitoring)
        // because we only want to test the logic functions (createBestItem).
        monitor = ClipboardMonitor(pasteboard: mockPasteboard)
    }
    
    override func tearDown() {
        monitor = nil
        mockPasteboard = nil
        super.tearDown()
    }
    
    // MARK: - Logic Tests (Synchronous)
    
    func testItemCreation_Text() {
        // Given
        let text = "Hello Unit Test"
        mockPasteboard.clearContents()
        mockPasteboard.setString(text, forType: .string)
        
        // When
        let item = monitor.createTextItem(bundleID: nil, appName: nil)
        
        // Then
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.content, text)
        XCTAssertEqual(item?.itemType, .text)
    }
    
    func testItemCreation_Link() {
        // Given
        let link = "https://swift.org"
        mockPasteboard.clearContents()
        mockPasteboard.setString(link, forType: .string)
        
        // When
        let item = monitor.createTextItem(bundleID: nil, appName: nil)
        
        // Then
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.itemType, .link)
        XCTAssertEqual(item?.content, link)
    }
    
    func testItemCreation_Color() {
        // Given
        mockPasteboard.clearContents()
        mockPasteboard.dataStore[.color] = NSColor.red
        
        // When
        // createBestItem uses 'readObjects' which calls our Mock's readObjects logic
        let types: [NSPasteboard.PasteboardType] = [.color]
        
        // We inject the Red color into the mock's dataStore directly so readObjects finds it
        // The mock 'readObjects' implementation below handles returning it
        
        // Testing specific 'createColorItem' logic
        // Note: ClipboardMonitor calls pasteboard.readObjects internally
        let item = monitor.createColorItem(bundleID: nil, appName: nil)
        
        // Then
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.itemType, .color)
        XCTAssertTrue(item?.content.contains("#FF0000") == true)
    }
    
    // MARK: - Change Detection Logic
    
    func testChangeDetectionTriggers() {
        // Setup expectation
        let expectation = expectation(description: "onNewItem called")
        var receivedItem: ClipboardItem?
        
        monitor.onNewItem = { item in
            receivedItem = item
            expectation.fulfill()
        }
        
        // Set initial state
        mockPasteboard.changeCount = 1
        monitor.lastChangeCount = 1
        
        // Simulate change
        mockPasteboard.setString("New Data", forType: .string)
        // changeCount increments to 2
        
        // Manually trigger check (bypassing Timer)
        monitor.checkForChanges()
        
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(receivedItem?.content, "New Data")
    }
}
