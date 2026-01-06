//
//  ContentView.swift
//  Clipmighty
//
//  Main content view for the status bar popover displaying clipboard history.
//  ClipboardItemRow is in Features/Clipboard/ClipboardItemRow.swift
//

import AppKit
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ClipboardMonitor.self) private var monitor

    @Query(sort: \ClipboardItem.timestamp, order: .reverse) private var items: [ClipboardItem]

    @State private var searchText = ""
    @State private var hoverItemId: UUID?

    // Grid/List configuration
    // Menu bar apps look good with a constrained list

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
        .onAppear {
            // Callback is now set up in ClipmightyApp.init(), no need for setupMonitor()
            lastSyncTime = Date()
        }
        .onChange(of: items) { _, _ in
            lastSyncTime = Date()
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
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredItems) { item in
                    ClipboardItemRow(
                        item: item,
                        isHovering: hoverItemId == item.id,
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
