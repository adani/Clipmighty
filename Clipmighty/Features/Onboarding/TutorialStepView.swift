//
//  TutorialStepView.swift
//  Clipmighty
//
//  Created on 2026-01-09.
//

import SwiftUI
import AppKit

/// Tutorial step view for onboarding
struct TutorialStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var copiedTexts = [
        "Hello from Clipmighty! 🎉",
        "Copy me and paste below!",
        "Your clipboard history awaits"
    ]
    @State private var showCopiedFeedback = false

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Quick Tutorial")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("""
                    Let's try out Clipmighty! Copy one of the texts below, \
                    then paste it using the shortcut.
                    """)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            .padding(.top, 16)

            // Copyable texts
            VStack(spacing: 8) {
                Text("Click to copy:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(copiedTexts, id: \.self) { text in
                    CopyableTextRow(
                        text: text,
                        isCopied: viewModel.tutorialCopiedText == text
                    ) {
                        copyText(text)
                    }
                }
            }

            // Status bar hint
            HStack(spacing: 12) {
                Image(systemName: "menubar.rectangle")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Find Clipmighty in your menu bar")
                        .font(.headline)

                    Text("Click the clipboard icon or use ⌃V to see your history")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 32)

            // Paste area
            VStack(spacing: 8) {
                Text("Paste here to complete:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Paste here...", text: $viewModel.tutorialPastedText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 400)
                    .onChange(of: viewModel.tutorialPastedText) {
                        viewModel.checkTutorialPaste()
                    }

                if viewModel.isTutorialComplete {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                            Text("Great!")
                                .font(.title2)
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        }
                        Text("You're ready to use Clipmighty!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private func copyText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        viewModel.tutorialCopiedText = text

        withAnimation {
            showCopiedFeedback = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                showCopiedFeedback = false
            }
        }
    }
}

/// Copyable text row for tutorial
struct CopyableTextRow: View {
    let text: String
    let isCopied: Bool
    let onCopy: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onCopy) {
            HStack {
                Text(text)
                    .font(.body)

                Spacer()

                if isCopied {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .padding(.horizontal, 32)
    }

    private var backgroundColor: Color {
        if isCopied {
            return Color.green.opacity(0.1)
        } else if isHovered {
            return Color.primary.opacity(0.05)
        } else {
            return Color.clear
        }
    }

    private var borderColor: Color {
        isCopied ? Color.green.opacity(0.3) : Color.primary.opacity(0.1)
    }
}
