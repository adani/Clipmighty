import AppKit
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ClipboardMonitor.self) private var monitor

    @Query(sort: \ClipboardItem.timestamp, order: .reverse) private var items: [ClipboardItem]

    @State private var searchText = ""
    @State private var hoverItemId: UUID?
    @State private var selectedItemId: UUID?
    @State private var keyEventMonitor: Any?
    @State private var hostWindow: NSWindow?
    @State private var rowFrames: [UUID: CGRect] = [:]
    @State private var viewportFrame: CGRect = .zero
    @State private var visibleIndexRange: ClosedRange<Int>?

    @Environment(\.openSettings) private var openSettings
    @State private var itemToEdit: ClipboardItem?

    @AppStorage("enableCloudSync") private var enableCloudSync: Bool = false
    @State private var lastSyncTime: Date = Date()

    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            clipboardListView

            if enableCloudSync {
                syncStatusView
            }
        }
        .frame(width: 350, height: 500)  // Standard Menu Bar sizing
        .background(.regularMaterial)  // Liquid Glass effect
        .background(
            WindowAccessorView { window in
                hostWindow = window
            }
        )
        .onAppear {
            // Callback is now set up in ClipmightyApp.init(), no need for setupMonitor()
            lastSyncTime = Date()
            ensureValidSelection()
            installKeyboardMonitor()
        }
        .onDisappear {
            removeKeyboardMonitor()
        }
        .onChange(of: items) { _, _ in
            lastSyncTime = Date()
            ensureValidSelection()
        }
        .onChange(of: filteredItems.map(\.id)) { _, _ in
            ensureValidSelection()
            updateVisibleIndexRange()
        }
        .sheet(item: $itemToEdit) { item in
            EditView(content: item.content, originalItem: item)
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search clipboard...", text: $searchText)
                .textFieldStyle(.plain)

            Spacer()

            Button(
                action: {
                    // Dispatch async to avoid "layoutSubtreeIfNeeded" recursion during view updates
                    DispatchQueue.main.async {
                        if let delegate = NSApp.delegate as? AppDelegate {
                            delegate.openSettings()
                        }
                        openSettings()
                    }
                },
                label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(.primary.opacity(0.8))
                }
            )
            .buttonStyle(.plain)

            Button(
                action: {
                    NSApp.terminate(nil)
                },
                label: {
                    Image(systemName: "power")
                        .foregroundColor(.primary.opacity(0.8))
                }
            )
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.1)),
            alignment: .bottom
        )
    }

    // MARK: - Clipboard List View

    private var clipboardListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredItems) { item in
                        ClipboardItemRow(
                            item: item,
                            isHovering: hoverItemId == item.id,
                            isSelected: selectedItemId == item.id,
                            onSelect: {
                                selectedItemId = item.id
                            },
                            onCopy: {
                                monitor.copyToClipboard(item)
                            },
                            onEdit: {
                                itemToEdit = item
                            },
                            onDelete: {
                                deleteItem(item)
                            }
                        )
                        .id(item.id)
                        .background(
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: MenuOverlayRowFramePreferenceKey.self,
                                    value: [item.id: geometry.frame(in: .named("menuOverlayScroll"))]
                                )
                            }
                        )
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                hoverItemId = hovering ? item.id : nil
                            }
                        }
                        .contextMenu {
                            Button("Edit") {
                                itemToEdit = item
                            }
                            Button("Delete", role: .destructive) {
                                deleteItem(item)
                            }
                            Button("Pin") {
                                togglePin(item)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .coordinateSpace(name: "menuOverlayScroll")
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: MenuOverlayViewportFramePreferenceKey.self,
                        value: geometry.frame(in: .named("menuOverlayScroll"))
                    )
                }
            )
            .onPreferenceChange(MenuOverlayRowFramePreferenceKey.self) { value in
                rowFrames = value
                updateVisibleIndexRange()
            }
            .onPreferenceChange(MenuOverlayViewportFramePreferenceKey.self) { value in
                viewportFrame = value
                updateVisibleIndexRange()
            }
            .onAppear {
                if let selectedItemId {
                    proxy.scrollTo(selectedItemId, anchor: .center)
                }
            }
            .onChange(of: selectedItemId) { _, newValue in
                guard let newValue else { return }
                withAnimation(.snappy(duration: 0.2)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    // MARK: - Sync Status View

    private var syncStatusView: some View {
        HStack(spacing: 6) {
            Image(systemName: "icloud.fill")
                .font(.system(size: 11))
                .foregroundColor(.blue)

            Text("iCloud Synced")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Spacer()

            Text(lastSyncTime, style: .relative)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text("ago")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.1)),
            alignment: .top
        )
    }

    // MARK: - Actions

    private func deleteItem(_ item: ClipboardItem) {
        withAnimation {
            modelContext.delete(item)
        }
    }

    private func togglePin(_ item: ClipboardItem) {
        item.isPinned.toggle()
    }
}

private extension ContentView {
    var selectedIndex: Int? {
        guard let selectedItemId else { return nil }
        return filteredItems.firstIndex { $0.id == selectedItemId }
    }

    func ensureValidSelection() {
        guard !filteredItems.isEmpty else {
            selectedItemId = nil
            return
        }

        if selectedItemId == nil || selectedIndex == nil {
            selectedItemId = filteredItems[0].id
        }
    }

    func selectItem(at index: Int) {
        guard filteredItems.indices.contains(index) else { return }
        selectedItemId = filteredItems[index].id
    }

    func moveSelection(by delta: Int) {
        guard !filteredItems.isEmpty else { return }
        let currentIndex = selectedIndex ?? 0
        let newIndex = max(0, min(currentIndex + delta, filteredItems.count - 1))
        selectItem(at: newIndex)
    }

    func moveSelectionToStart() {
        guard !filteredItems.isEmpty else { return }
        selectItem(at: 0)
    }

    func moveSelectionToEnd() {
        guard !filteredItems.isEmpty else { return }
        selectItem(at: filteredItems.count - 1)
    }

    func moveSelectionPageDown() {
        guard !filteredItems.isEmpty else { return }
        if let visibleIndexRange {
            selectItem(at: min(visibleIndexRange.upperBound + 1, filteredItems.count - 1))
            return
        }
        moveSelection(by: 1)
    }

    func moveSelectionPageUp() {
        guard !filteredItems.isEmpty else { return }
        if let visibleIndexRange {
            selectItem(at: max(visibleIndexRange.lowerBound - 1, 0))
            return
        }
        moveSelection(by: -1)
    }

    func copySelectedItem() {
        guard let index = selectedIndex,
              filteredItems.indices.contains(index) else { return }
        monitor.copyToClipboard(filteredItems[index])
    }

    func installKeyboardMonitor() {
        if keyEventMonitor != nil { return }
        keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyboardEvent(event) ? nil : event
        }
    }

    func removeKeyboardMonitor() {
        guard let keyEventMonitor else { return }
        NSEvent.removeMonitor(keyEventMonitor)
        self.keyEventMonitor = nil
    }

    func canHandleKeyboardEvent(_ event: NSEvent) -> Bool {
        guard let hostWindow, event.window == hostWindow, hostWindow.isVisible else {
            return false
        }

        if event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command) {
            return false
        }

        if event.window?.firstResponder is NSTextView {
            return false
        }

        return !filteredItems.isEmpty
    }

    func updateVisibleIndexRange() {
        guard !filteredItems.isEmpty else {
            visibleIndexRange = nil
            return
        }

        let visibleIndices = rowFrames.reduce(into: [Int]()) { partialResult, entry in
            let frame = entry.value
            guard frame.maxY > viewportFrame.minY,
                  frame.minY < viewportFrame.maxY else {
                return
            }

            if let index = filteredItems.firstIndex(where: { $0.id == entry.key }) {
                partialResult.append(index)
            }
        }.sorted()

        guard let first = visibleIndices.first,
              let last = visibleIndices.last else {
            visibleIndexRange = nil
            return
        }

        visibleIndexRange = first...last
    }

    func handleKeyboardEvent(_ event: NSEvent) -> Bool {
        guard canHandleKeyboardEvent(event) else { return false }

        switch event.keyCode {
        case 125:
            moveSelection(by: 1)
            return true
        case 126:
            moveSelection(by: -1)
            return true
        case 121:
            moveSelectionPageDown()
            return true
        case 116:
            moveSelectionPageUp()
            return true
        case 115:
            moveSelectionToStart()
            return true
        case 119:
            moveSelectionToEnd()
            return true
        case 36, 76:
            copySelectedItem()
            return true
        default:
            return false
        }
    }
}
