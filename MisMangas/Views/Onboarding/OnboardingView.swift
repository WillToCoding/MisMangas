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
            // MARK: - Page Content
            TabView(selection: $currentPage) {
                // Página 1: Descubre
                OnboardingPage(
                    title: "onboarding_discover_title",
                    imageName: "OnboardingMascot",
                    features: [
                        OnboardingFeature(icon: "books.vertical.fill", color: .purple, title: "onboarding_catalog_title", description: "onboarding_catalog_description"),
                        OnboardingFeature(icon: "slider.horizontal.3", color: .blue, title: "onboarding_filters_title", description: "onboarding_filters_description"),
                        OnboardingFeature(icon: "info.circle.fill", color: .indigo, title: "onboarding_details_title", description: "onboarding_details_description"),
                        OnboardingFeature(icon: "link", color: .cyan, title: "onboarding_related_title", description: "onboarding_related_description")
                    ]
                )
                .tag(0)

                // Página 2: Colecciona
                OnboardingPage(
                    title: "onboarding_collect_title",
                    imageName: "OnboardingMascot",
                    features: [
                        OnboardingFeature(icon: "heart.fill", color: .red, title: "onboarding_favorites_title", description: "onboarding_favorites_description"),
                        OnboardingFeature(icon: "book.fill", color: .green, title: "onboarding_progress_title", description: "onboarding_progress_description"),
                        OnboardingFeature(icon: "icloud.fill", color: .blue, title: "onboarding_sync_title", description: "onboarding_sync_description"),
                        OnboardingFeature(icon: "internaldrive.fill", color: .orange, title: "onboarding_offline_title", description: "onboarding_offline_description")
                    ]
                )
                .tag(1)

                // Página 3: Personaliza
                OnboardingPage(
                    title: "onboarding_customize_title",
                    imageName: "OnboardingMascot",
                    features: [
                        OnboardingFeature(icon: "square.grid.2x2.fill", color: .pink, title: "onboarding_widgets_title", description: "onboarding_widgets_description"),
                        OnboardingFeature(icon: "lock.rectangle.fill", color: .purple, title: "onboarding_lockscreen_title", description: "onboarding_lockscreen_description"),
                        OnboardingFeature(icon: "mic.fill", color: .indigo, title: "onboarding_siri_title", description: "onboarding_siri_description"),
                        OnboardingFeature(icon: "globe", color: .teal, title: "onboarding_languages_title", description: "onboarding_languages_description")
                    ]
                )
                .tag(2)
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .animation(.easeInOut, value: currentPage)

            // MARK: - Page Indicators
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

            // MARK: - Navigation Buttons
            HStack(spacing: 16) {
                if currentPage > 0 {
                    Button {
                        withAnimation {
                            currentPage -= 1
                        }
                    } label: {
                        Text("onboarding_back")
                            .font(.headline)
                            .foregroundStyle(.purple)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.purple.opacity(0.15), in: .rect(cornerRadius: 12))
                    }
                }

                Button {
                    if currentPage < totalPages - 1 {
                        withAnimation {
                            currentPage += 1
                        }
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
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        #if os(macOS)
        .background(Color(NSColor.windowBackgroundColor))
        #elseif os(watchOS) || os(tvOS)
        .background(Color.black)
        #else
        .background(Color(.systemBackground))
        #endif
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

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 40)

            // Title
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Mascot
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .clipShape(.rect(cornerRadius: 28))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                .padding(.top, 16)
                .padding(.bottom, 24)
                .accessibilityHidden(true)

            // Features
            VStack(alignment: .leading, spacing: 20) {
                ForEach(features) { feature in
                    FeatureRow(feature: feature)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let feature: OnboardingFeature

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: feature.icon)
                .font(.title3)
                .foregroundStyle(feature.color)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(feature.description)
                    .font(.caption)
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
