//
//  ClipboardItemRow.swift
//  Clipmighty
//
//  Individual row view for displaying a clipboard item in the list.
//

import AppKit
import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isHovering: Bool
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isCopied = false
    @State private var isPendingDeletion = false
    @State private var deletionTask: DispatchWorkItem?

    var body: some View {
        ZStack {
            if isPendingDeletion {
                deletionGraceView
            } else {
                normalContentView
                    .overlay(
                        hoverActionButtons,
                        alignment: .bottomTrailing
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                // Use systematic colors for light/dark mode compatibility
                .fill(
                    isCopied
                        ? Color.green.opacity(0.1)
                        : Color.primary.opacity(isHovering && !isPendingDeletion ? 0.05 : 0.0)
                )
                .animation(.easeInOut(duration: 0.2), value: isCopied)
        )
        .contentShape(Rectangle())  // Make entire row tappable
        .onTapGesture {
            if !isPendingDeletion {
                handleCopy()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ClipboardRow")
        .accessibilityLabel(item.content)
    }

    // MARK: - Normal Content View

    private var normalContentView: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                // Content View based on Type
                contentView

                // Metadata row
                metadataRow
            }

            Spacer()

            // Pin Status
            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
        .overlay(
            Group {
                if isCopied {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                        .background(Color.white.clipShape(Circle()))  // Ensure visibility over content
                        .transition(.scale.combined(with: .opacity))
                        .padding(.leading, 8)
                }
            },
            alignment: .trailing
        )
    }

    // MARK: - Deletion Grace View

    private var deletionGraceView: some View {
        HStack {
            Image(systemName: "trash.fill")
                .foregroundColor(.red)
            Text("Deleted")
                .foregroundColor(.secondary)

            Spacer()

            Button(action: {
                cancelDeletion()
            }, label: {
                Text("Undo")
            })
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .controlSize(.small)
        }
    }

    // MARK: - Hover Action Buttons

    @ViewBuilder
    private var hoverActionButtons: some View {
        if isHovering && !isCopied {
            HStack(spacing: 16) {
                Button(action: {
                    onEdit()
                }, label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.8))
                })
                .buttonStyle(.plain)

                Button(action: {
                    startDeletionGracePeriod()
                }, label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red.opacity(0.9))
                })
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .offset(x: -8, y: -8)
            .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .bottomTrailing)))
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch item.itemType {
        case .image:
            imageContentView

        case .color:
            colorContentView

        case .file:
            fileContentView

        case .link:
            Text(item.content)
                .lineLimit(2)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.blue)

        case .webContent:
            Text("🌐 " + item.content)
                .lineLimit(3)
                .font(.system(size: 13))
                .foregroundColor(.primary)

        default:
            Text(item.content)
                .lineLimit(2)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.primary)
        }
    }

    @ViewBuilder
    private var imageContentView: some View {
        if let data = item.imageData, let img = NSImage(data: data) {
            Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 100)
                .cornerRadius(4)
        } else {
            Text("🖼️ Image (Unavailable)")
                .italic()
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var colorContentView: some View {
        HStack {
            if let data = item.colorData,
                let color = try? NSKeyedUnarchiver.unarchivedObject(
                    ofClass: NSColor.self, from: data) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(nsColor: color))
                    .frame(width: 40, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4).stroke(
                            Color.primary.opacity(0.1), lineWidth: 1))
            }
            Text(item.content)  // Hex Code
                .font(.system(.body, design: .monospaced))
        }
    }

    @ViewBuilder
    private var fileContentView: some View {
        HStack {
            Image(systemName: "doc.fill")
                .foregroundColor(.blue)
            Text(item.content)  // Filename
                .font(.headline)
        }
        if let url = item.fileURL {
            Text(url.path)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    // MARK: - Metadata Row

    private var metadataRow: some View {
        HStack(spacing: 6) {
            // App Icon
            if let bundleID = item.sourceAppBundleID,
                let appIcon = getAppIcon(for: bundleID) {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            }

            // App Name
            if let appName = item.sourceAppName {
                Text(appName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // Timestamp
            Text(item.timestamp, style: .time)
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.8))
        }
    }

    // MARK: - Helpers

    private func getAppIcon(for bundleID: String) -> NSImage? {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return nil
    }

    // MARK: - Actions

    private func handleCopy() {
        onCopy()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isCopied = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                isCopied = false
            }
        }
    }

    private func startDeletionGracePeriod() {
        withAnimation {
            isPendingDeletion = true
        }

        let task = DispatchWorkItem {
            if isPendingDeletion {
                onDelete()
                // Do not reset isPendingDeletion here because the item will be removed from view
            }
        }

        deletionTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: task)
    }

    private func cancelDeletion() {
        deletionTask?.cancel()
        deletionTask = nil
        withAnimation {
            isPendingDeletion = false
        }
    }
}
