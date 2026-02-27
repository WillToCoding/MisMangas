//
//  OnboardingData.swift
//  MisMangas
//
//  Created by Juan Carlos on 24/2/26.
//

import SwiftUI


enum OnboardingData {
    @MainActor static let discoverFeatures: [OnboardingFeature] = [
        OnboardingFeature(icon: "books.vertical.fill", color: .purple, title: "onboarding_catalog_title", description: "onboarding_catalog_description"),
        OnboardingFeature(icon: "slider.horizontal.3", color: .blue, title: "onboarding_filters_title", description: "onboarding_filters_description"),
        OnboardingFeature(icon: "info.circle.fill", color: .indigo, title: "onboarding_details_title", description: "onboarding_details_description"),
        OnboardingFeature(icon: "link", color: .cyan, title: "onboarding_related_title", description: "onboarding_related_description")
    ]

    @MainActor static let collectFeatures: [OnboardingFeature] = [
        OnboardingFeature(icon: "heart.fill", color: .red, title: "onboarding_favorites_title", description: "onboarding_favorites_description"),
        OnboardingFeature(icon: "book.fill", color: .green, title: "onboarding_progress_title", description: "onboarding_progress_description"),
        OnboardingFeature(icon: "icloud.fill", color: .blue, title: "onboarding_sync_title", description: "onboarding_sync_description"),
        OnboardingFeature(icon: "internaldrive.fill", color: .orange, title: "onboarding_offline_title", description: "onboarding_offline_description")
    ]

    @MainActor static let customizeFeatures: [OnboardingFeature] = [
        OnboardingFeature(icon: "square.grid.2x2.fill", color: .pink, title: "onboarding_widgets_title", description: "onboarding_widgets_description"),
        OnboardingFeature(icon: "lock.rectangle.fill", color: .purple, title: "onboarding_lockscreen_title", description: "onboarding_lockscreen_description"),
        OnboardingFeature(icon: "mic.fill", color: .indigo, title: "onboarding_siri_title", description: "onboarding_siri_description"),
        OnboardingFeature(icon: "globe", color: .teal, title: "onboarding_languages_title", description: "onboarding_languages_description")
    ]
}

