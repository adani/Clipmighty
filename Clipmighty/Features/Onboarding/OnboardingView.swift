//
//  OnboardingView.swift
//  Clipmighty
//
//  Created on 2026-01-09.
//

import SwiftUI
import AppKit

/// Main onboarding view with step-based navigation
struct OnboardingView: View {
    @State var viewModel: OnboardingViewModel
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // Animated background
            AnimatedGradientBackground()

            VStack(spacing: 0) {
                // Content area with scroll support
                ScrollView {
                    Group {
                        switch viewModel.currentStep {
                        case .welcome:
                            WelcomeStepView(viewModel: viewModel)
                        case .permissions:
                            PermissionsStepView(viewModel: viewModel)
                        case .excludedApps:
                            ExcludedAppsStepView(viewModel: viewModel)
                        case .tutorial:
                            TutorialStepView(viewModel: viewModel)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(viewModel.currentStep)

                // Navigation footer
                OnboardingFooter(viewModel: viewModel, onComplete: onComplete)
            }
        }
        .frame(width: 600, height: 600)
    }
}

// MARK: - Animated Background

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false

    var body: some View {
        LinearGradient(
            colors: [
                Color(nsColor: .controlBackgroundColor),
                Color.accentColor.opacity(0.1),
                Color.purple.opacity(0.05),
                Color(nsColor: .controlBackgroundColor)
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Navigation Footer

struct OnboardingFooter: View {
    @Bindable var viewModel: OnboardingViewModel
    var onComplete: () -> Void

    var body: some View {
        HStack {
            // Back button area (fixed width to prevent shifting)
            HStack {
                if viewModel.currentStep != .welcome {
                    Button(
                        action: { viewModel.previousStep() },
                        label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                    )
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
            }
            .frame(width: 80, alignment: .leading)

            Spacer()

            // Step indicators (centered)
            HStack(spacing: 8) {
                ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                    Circle()
                        .fill(step == viewModel.currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(step == viewModel.currentStep ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.currentStep)
                }
            }

            Spacer()

            // Next/Complete button (fixed width to balance layout)
            HStack {
                nextButton
            }
            .frame(width: 120, alignment: .trailing)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .background(.regularMaterial)
    }

    @ViewBuilder
    private var nextButton: some View {
        if viewModel.currentStep == .tutorial {
            Button(
                action: {
                    viewModel.completeOnboarding()
                    onComplete()
                },
                label: {
                    HStack(spacing: 4) {
                        Text("Get Started")
                        Image(systemName: "arrow.right")
                    }
                }
            )
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isTutorialComplete)
        } else if viewModel.currentStep == .permissions && !viewModel.hasAccessibilityPermission {
            Button(
                action: { viewModel.nextStep() },
                label: { Text("Skip for now") }
            )
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        } else {
            Button(
                action: { viewModel.nextStep() },
                label: {
                    HStack(spacing: 4) {
                        Text("Continue")
                        Image(systemName: "chevron.right")
                    }
                }
            )
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canProceed)
        }
    }
}
