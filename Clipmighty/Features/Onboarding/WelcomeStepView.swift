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
                Text("Welcome to Clipmighty")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your powerful clipboard manager")
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
                Text("By continuing, you agree to our")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // swiftlint:disable:next force_unwrapping
                Link("Terms of Service", destination: URL(string: "https://nalarin.com/clipmighty/terms")!)
                    .font(.caption)

                Text("and")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // swiftlint:disable:next force_unwrapping
                Link("Privacy Policy", destination: URL(string: "https://nalarin.com/clipmighty/privacy")!)
                    .font(.caption)
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 48)
    }
}
