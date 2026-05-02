//
//  WelcomeStepView.swift
//  Clipmighty
//
//  Created on 2026-01-09.
//

import SwiftUI
import AppKit

/// Welcome step view for onboarding
struct WelcomeStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App Icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .shadow(color: .accentColor.opacity(0.3), radius: 20, x: 0, y: 10)

            // Welcome text
            VStack(spacing: 8) {
                Text(L10n.onboardingWelcomeTitle.text)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(L10n.onboardingWelcomeSubtitle.text)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            // Rotating features
            Text(viewModel.features[viewModel.currentFeatureIndex])
                .font(.headline)
                .foregroundColor(.accentColor)
                .frame(height: 30)
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentFeatureIndex)
                .contentTransition(.opacity)

            Spacer()

            // Terms and Privacy links
            HStack(spacing: 4) {
                Text(L10n.onboardingTermsPrefix.text)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // swiftlint:disable:next force_unwrapping
                Link(
                    L10n.onboardingTermsOfService.string,
                    destination: URL(string: "https://nalarin.com/clipmighty/terms")!
                )
                    .font(.caption)

                Text(L10n.onboardingTermsAnd.text)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // swiftlint:disable:next force_unwrapping
                Link(
                    L10n.onboardingPrivacyPolicy.string,
                    destination: URL(string: "https://nalarin.com/clipmighty/privacy")!
                )
                    .font(.caption)
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 48)
    }
}
