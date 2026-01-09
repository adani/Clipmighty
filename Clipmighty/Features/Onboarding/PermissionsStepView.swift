//
//  PermissionsStepView.swift
//  Clipmighty
//
//  Created on 2026-01-09.
//

import SwiftUI

/// Permissions step view for onboarding
struct PermissionsStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: "hand.raised.fingers.spread")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, options: .repeating)

            VStack(spacing: 12) {
                Text("Accessibility Permission")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("""
                    Clipmighty needs Accessibility permission to detect which app you \
                    copied from and to paste clipboard items directly into your apps.
                    """)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            // Permission status
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    let iconName = viewModel.hasAccessibilityPermission
                        ? "checkmark.circle.fill" : "xmark.circle"
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(viewModel.hasAccessibilityPermission ? .green : .orange)

                    Text(viewModel.hasAccessibilityPermission ? "Permission Granted" : "Permission Required")
                        .font(.headline)
                        .foregroundColor(viewModel.hasAccessibilityPermission ? .green : .primary)
                }

                if !viewModel.hasAccessibilityPermission {
                    Button(
                        action: { viewModel.requestAccessibilityPermission() },
                        label: {
                            HStack {
                                Image(systemName: "gear")
                                Text("Open System Settings")
                            }
                        }
                    )
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

            // Privacy note
            VStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .font(.title3)
                    .foregroundColor(.secondary)

                Text("We respect your privacy")
                    .font(.headline)

                Text("""
                    This permission is only used to identify source apps and enable paste \
                    functionality. We never access or transmit your data.
                    """)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 350)
            }

            Spacer()
        }
        .padding(.horizontal, 48)
        .onAppear {
            viewModel.checkAccessibilityPermission()
        }
    }
}
