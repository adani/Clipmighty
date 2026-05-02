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
                Text(L10n.onboardingPermissionsTitle.text)
                    .font(.title)
                    .fontWeight(.semibold)

                Text(L10n.onboardingPermissionsDescription.text)
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

                    Text(
                        viewModel.hasAccessibilityPermission
                        ? L10n.onboardingPermissionGranted.text
                        : L10n.onboardingPermissionRequired.text
                    )
                        .font(.headline)
                        .foregroundColor(viewModel.hasAccessibilityPermission ? .green : .primary)
                }

                if !viewModel.hasAccessibilityPermission {
                    Button(
                        action: { viewModel.requestAccessibilityPermission() },
                        label: {
                            HStack {
                                Image(systemName: "gear")
                                Text(L10n.onboardingOpenSystemSettings.text)
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

                Text(L10n.onboardingPrivacyFirst.text)
                    .font(.headline)

                Text(L10n.onboardingPrivacyFirstDescription.text)
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
