//
//  VisionSettingsView.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 26/02/26.
//

import SwiftUI

struct VisionSettingsView: View {
    @State private var deeplApiKey: String = ""

    @Environment(TranslationService.self) private var translationService
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                translationSection
                aboutSection
            }
            .padding(40)
        }
        .navigationTitle("settings_title")
        .onAppear {
            deeplApiKey = translationService.apiKey
        }
    }

    // MARK: - Translation Section

    private var translationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("translation_settings_title", systemImage: "globe")
                    .font(.title2.bold())
                    .foregroundStyle(.purple)

                Spacer()

                if translationService.isConfigured {
                    Label("translation_settings_configured", systemImage: "checkmark.circle.fill")
                        .font(.callout)
                        .foregroundStyle(.green)
                }
            }

            Text("translation_settings_footer")
                .font(.callout)
                .foregroundStyle(.secondary)

            SecureField("translation_settings_api_key_placeholder", text: $deeplApiKey)
                .textFieldStyle(.roundedBorder)
                .onChange(of: deeplApiKey) { _, newValue in
                    translationService.apiKey = newValue
                }
        }
        .padding(30)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("profile_about", systemImage: "info.circle.fill")
                .font(.title2.bold())
                .foregroundStyle(.gray)

            HStack {
                Text("profile_version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
            .font(.title3)

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                VisionLinkRow(
                    icon: "hand.raised.fill",
                    title: "profile_privacy_policy",
                    url: "https://www.willtocoding.com/projects/mismangas/privacy"
                )

                VisionLinkRow(
                    icon: "doc.text.fill",
                    title: "profile_terms_of_service",
                    url: "https://www.willtocoding.com/projects/mismangas/terms"
                )

                VisionLinkRow(
                    icon: "accessibility",
                    title: "profile_accessibility",
                    url: "https://www.willtocoding.com/projects/mismangas/accessibility"
                )

                VisionLinkRow(
                    icon: "envelope.fill",
                    title: "profile_contact",
                    url: "https://www.willtocoding.com/projects/mismangas/contact"
                )
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Vision Link Row

struct VisionLinkRow: View {
    let icon: String
    let title: LocalizedStringKey
    let url: String

    private var displayURL: String {
        url.replacingOccurrences(of: "https://", with: "")
    }

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .frame(width: 24)

                Text(title)
                    .foregroundStyle(.primary)

                Spacer()

                Text(displayURL)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .font(.title3)
        }
        .buttonStyle(.plain)
        .hoverEffect()
    }
}

#Preview {
    NavigationStack {
        VisionSettingsView()
    }
    .environment(TranslationService())
}

#Preview("Link Row") {
    VisionLinkRow(
        icon: "envelope.fill",
        title: "Contact",
        url: "https://example.com"
    )
    .padding()
}
