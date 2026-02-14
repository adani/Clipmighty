import AppKit
import SwiftUI

struct OverlayView: View {
    @Bindable var viewModel: OverlayViewModel
    @State private var rowFrames: [Int: CGRect] = [:]
    @State private var viewportFrame: CGRect = .zero

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "clipboard")
                Text("Clipboard History")
                    .font(.headline)
                Spacer()
                Text(pasteInstructionText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.regularMaterial)
            .onAppear {
                viewModel.checkAccessibility()
            }

            // List
            ScrollViewReader { proxy in
                if viewModel.items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clipboard")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No Clipboard History")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Copy something to see it here.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 40)
                    .onAppear {
                        viewModel.visibleIndexRange = nil
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                                ItemRow(item: item, isSelected: index == viewModel.selectedIndex)
                                    .id(index)
                                    .background(
                                        GeometryReader { geometry in
                                            Color.clear.preference(
                                                key: OverlayRowFramePreferenceKey.self,
                                                value: [index: geometry.frame(in: .named("overlayListScroll"))]
                                            )
                                        }
                                    )
                                    .onTapGesture {
                                        viewModel.selectedIndex = index
                                    }
                            }
                        }
                        .id(viewModel.viewID)
                        .padding(.vertical, 4)
                    }
                    .coordinateSpace(name: "overlayListScroll")
                    .background(
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: OverlayViewportFramePreferenceKey.self,
                                value: geometry.frame(in: .named("overlayListScroll"))
                            )
                        }
                    )
                    .scrollIndicators(.visible)
                    .onPreferenceChange(OverlayRowFramePreferenceKey.self) { value in
                        rowFrames = value
                        updateVisibleIndexRange()
                    }
                    .onPreferenceChange(OverlayViewportFramePreferenceKey.self) { value in
                        viewportFrame = value
                        updateVisibleIndexRange()
                    }
                    .onAppear {
                        // Scroll to selected index when view appears
                        proxy.scrollTo(viewModel.selectedIndex, anchor: .center)
                    }
                    .onChange(of: viewModel.selectedIndex) { _, newIndex in
                        withAnimation(.snappy(duration: 0.2)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 480, idealWidth: 500, maxWidth: 600, minHeight: 300, idealHeight: 450, maxHeight: 500)
        .background(.regularMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )

    }

    private var pasteInstructionText: String {
        let pinInstruction = "Use \(OverlayPinShortcut.formattedShortcut()) to pin/unpin"

        if viewModel.isAccessibilityTrusted {
            return "↵ to paste • \(pinInstruction)"
        } else {
            return "↵ to copy • \(pinInstruction)"
        }
    }

    private func updateVisibleIndexRange() {
        guard !viewModel.items.isEmpty else {
            viewModel.visibleIndexRange = nil
            return
        }

        let visibleIndices = rowFrames
            .compactMap { index, frame in
                frame.maxY > viewportFrame.minY && frame.minY < viewportFrame.maxY ? index : nil
            }
            .sorted()

        guard let first = visibleIndices.first,
              let last = visibleIndices.last else {
            viewModel.visibleIndexRange = nil
            return
        }

        viewModel.visibleIndexRange = first...last
    }
}

private struct OverlayRowFramePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]

    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, latest in latest })
    }
}

private struct OverlayViewportFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct ItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // App Icon
            appIconView

            VStack(alignment: .leading, spacing: 4) {
                // Content View based on Type
                contentView

                // Metadata row
                metadataRow
            }

            Spacer()

            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.85) : .yellow)
            }

            if isSelected {
                Image(systemName: "return")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor : Color.clear)
        .contentShape(Rectangle())
    }

    // MARK: - App Icon View

    @ViewBuilder
    private var appIconView: some View {
        ZStack {
            if let bundleID = item.sourceAppBundleID,
               let appIcon = getAppIcon(for: bundleID) {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
            } else if let appName = item.sourceAppName, !appName.isEmpty {
                Text(String(appName.prefix(1)).uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isSelected ? .white : .primary)
            } else {
                Image(systemName: "doc.text")
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? .white : .secondary)
            }
        }
        .frame(width: 20, height: 20)
        .background(isSelected ? Color.white.opacity(0.2) : Color.gray.opacity(0.2))
        .clipShape(Circle())
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
                .lineLimit(1)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(isSelected ? .white : .blue)

        case .webContent:
            Text("🌐 " + item.content)
                .lineLimit(1)
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? .white : .primary)

        default:
            Text(item.content.trimmingCharacters(in: .whitespacesAndNewlines))
                .lineLimit(1)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(isSelected ? .white : .primary)
        }
    }

    @ViewBuilder
    private var imageContentView: some View {
        HStack(spacing: 8) {
            if let data = item.imageData, let img = NSImage(data: data) {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 60)
                    .cornerRadius(4)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.system(size: 11))
                    Text("Image")
                        .font(.system(size: 13))
                }
                .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
        }
    }

    @ViewBuilder
    private var colorContentView: some View {
        HStack(spacing: 8) {
            if let data = item.colorData,
               let color = try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: NSColor.self, from: data) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(nsColor: color))
                    .frame(width: 30, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )
            }
            Text(item.content)  // Hex Code
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(isSelected ? .white : .primary)
        }
    }

    @ViewBuilder
    private var fileContentView: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.fill")
                .font(.system(size: 11))
                .foregroundStyle(isSelected ? .white : .blue)
            Text(item.content)  // Filename
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .foregroundStyle(isSelected ? .white : .primary)
        }
    }

    // MARK: - Metadata Row

    private var metadataRow: some View {
        HStack(spacing: 4) {
            if let appName = item.sourceAppName {
                Text(appName)
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
            }
            Text("•")
                .font(.system(size: 10))
                .foregroundStyle(isSelected ? .white.opacity(0.5) : .secondary.opacity(0.7))
            Text(item.timestamp.relativeTimestamp())
                .font(.system(size: 10))
                .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
        }
    }

    // MARK: - Helpers

    private func getAppIcon(for bundleID: String) -> NSImage? {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return nil
    }
}
