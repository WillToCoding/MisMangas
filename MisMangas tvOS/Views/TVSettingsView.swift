//
//  TVSettingsView.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct TVSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var deeplApiKey: String = ""

    @Environment(TranslationService.self) private var translationService
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        ScrollView {
            VStack(spacing: 60) {
                // MARK: - Back Button
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Label("action_back", systemImage: "chevron.left")
                            .font(.system(size: 32, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
                .focusSection()

                // MARK: - Traducción (DeepL)
                translationSection

                // MARK: - Acerca de
                aboutSection

                Spacer(minLength: 50)
            }
            .padding(80)
        }
        .navigationTitle("settings_title")
        .onAppear {
            deeplApiKey = translationService.apiKey
        }
        .onExitCommand {
            dismiss()
        }
    }

    // MARK: - Translation Section

    private var translationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label("translation_settings_title", systemImage: "globe")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.purple)

                Spacer()

                if translationService.isConfigured {
                    Label("translation_settings_configured", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.green)
                }
            }

            Text("translation_settings_footer")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)

            SecureField("translation_settings_api_key_placeholder", text: $deeplApiKey)
                .font(.system(size: 28))
                .textFieldStyle(.plain)
                .padding(20)
                .background(.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                .onChange(of: deeplApiKey) { _, newValue in
                    translationService.apiKey = newValue
                }
        }
        .padding(40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 24))
        .focusSection()
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Label("profile_about", systemImage: "info.circle.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.gray)

            HStack {
                Text("profile_version")
                    .font(.system(size: 28))
                Spacer()
                Text(appVersion)
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            }

            Divider()
                .background(.secondary)

            VStack(alignment: .leading, spacing: 20) {
                TVLinkRow(
                    icon: "hand.raised.fill",
                    title: "profile_privacy_policy",
                    url: "www.willtocoding.com/proyectos/mismangas/privacy"
                )

                TVLinkRow(
                    icon: "doc.text.fill",
                    title: "profile_terms_of_service",
                    url: "www.willtocoding.com/proyectos/mismangas/terms"
                )

                TVLinkRow(
                    icon: "accessibility",
                    title: "profile_accessibility",
                    url: "www.willtocoding.com/proyectos/mismangas/accessibility"
                )

                TVLinkRow(
                    icon: "envelope.fill",
                    title: "profile_contact",
                    url: "www.willtocoding.com/proyectos/mismangas/contact"
                )
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - TV Link Row

struct TVLinkRow: View {
    let icon: String
    let title: LocalizedStringKey
    let url: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(.blue)
                .frame(width: 40)

            Text(title)
                .font(.system(size: 28))

            Spacer()

            Text(url)
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Settings View") {
    NavigationStack {
        TVSettingsView()
    }
    .environment(TranslationService())
}

#Preview("Link Row") {
    TVLinkRow(
        icon: "hand.raised.fill",
        title: "profile_privacy_policy",
        url: "www.example.com/privacy"
    )
    .padding(40)
}
