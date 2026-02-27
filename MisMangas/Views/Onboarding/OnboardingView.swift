//
//  OnboardingView.swift
//  MisMangas
//
//  Created by Juan Carlos on 21/2/26.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let totalPages = 3

    var body: some View {
        VStack(spacing: 0) {
            pagesTabView
            pageIndicators
            navigationButtons
        }
        #if os(macOS)
        .background(Color(NSColor.windowBackgroundColor))
        #elseif os(watchOS) || os(tvOS)
        .background(Color.black)
        #else
        .background(Color(.systemBackground))
        #endif
    }

    private var pagesTabView: some View {
        TabView(selection: $currentPage) {
            OnboardingPage(title: "onboarding_discover_title", imageName: "OnboardingMascot", features: OnboardingData.discoverFeatures).tag(0)
            OnboardingPage(title: "onboarding_collect_title", imageName: "OnboardingMascot", features: OnboardingData.collectFeatures).tag(1)
            OnboardingPage(title: "onboarding_customize_title", imageName: "OnboardingMascot", features: OnboardingData.customizeFeatures).tag(2)
        }
        #if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
        #endif
        .animation(.easeInOut, value: currentPage)
    }

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? Color.purple : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(currentPage == index ? 1.2 : 1.0)
                    .animation(.spring(duration: 0.3), value: currentPage)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 24)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "accessibility_page_indicator \(currentPage + 1) \(totalPages)"))
    }

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentPage > 0 {
                backButton
            }
            nextButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    private var backButton: some View {
        Button {
            withAnimation { currentPage -= 1 }
        } label: {
            Text("onboarding_back")
                .font(.headline)
                .foregroundStyle(.purple)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.purple.opacity(0.15), in: .rect(cornerRadius: 12))
        }
        .accessibilityHint(String(localized: "accessibility_go_previous_page"))
    }

    private var nextButton: some View {
        Button {
            if currentPage < totalPages - 1 {
                withAnimation { currentPage += 1 }
            } else {
                hasSeenOnboarding = true
                dismiss()
            }
        } label: {
            Text(currentPage < totalPages - 1 ? "onboarding_next" : "onboarding_start")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.purple, in: .rect(cornerRadius: 12))
        }
        .accessibilityHint(currentPage < totalPages - 1 ? String(localized: "accessibility_go_next_page") : String(localized: "accessibility_finish_onboarding"))
    }
}


// MARK: - Onboarding Feature Model

struct OnboardingFeature: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: LocalizedStringKey
    let description: LocalizedStringKey
}

// MARK: - Onboarding Page

private struct OnboardingPage: View {
    let title: LocalizedStringKey
    let imageName: String
    let features: [OnboardingFeature]

    private var mascotImage: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 150, maxHeight: 150)
            .clipShape(.rect(cornerRadius: 28))
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            .padding(.bottom, 8)
            .accessibilityHidden(true)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .accessibilityHeader(.h1)

                // Mascot
                mascotImage

                // Features
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(features) { feature in
                        FeatureRow(feature: feature)
                    }
                }
                .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 20)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let feature: OnboardingFeature

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: feature.icon)
                .font(.title2)
                .foregroundStyle(feature.color)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
