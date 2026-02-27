//
//  MacSettingsView.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 22/2/26.
//

import SwiftUI

struct MacSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TranslationService.self) private var translationService

    @State private var deeplApiKey: String = ""

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            ScrollView {
                VStack(spacing: 24) {
                    translationSection
                    aboutSection
                }
                .padding(20)
            }
        }
        .onAppear {
            deeplApiKey = translationService.apiKey
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("settings_title")
                .font(.title2.bold())
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    // MARK: - Translation Section

    private var translationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("translation_settings_title", systemImage: "globe")
                    .font(.headline)
                    .foregroundStyle(.purple)
                Spacer()
                if translationService.isConfigured {
                    Label("translation_settings_configured", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Text("translation_settings_footer")
                .font(.caption)
                .foregroundStyle(.secondary)

            SecureField("translation_settings_api_key_placeholder", text: $deeplApiKey)
                .textFieldStyle(.roundedBorder)
                .onChange(of: deeplApiKey) { _, newValue in
                    translationService.apiKey = newValue
                }
        }
        .padding(16)
        .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("profile_about", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundStyle(.gray)

            HStack {
                Text("profile_version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            Divider()

            aboutLink(icon: "hand.raised.fill", title: "profile_privacy_policy", url: "https://www.willtocoding.com/projects/mismangas/privacy")
            aboutLink(icon: "doc.text.fill", title: "profile_terms_of_service", url: "https://www.willtocoding.com/projects/mismangas/terms")
            aboutLink(icon: "accessibility", title: "profile_accessibility", url: "https://www.willtocoding.com/projects/mismangas/accessibility")
            aboutLink(icon: "envelope.fill", title: "profile_contact", url: "https://www.willtocoding.com/projects/mismangas/contact")
        }
        .padding(16)
        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private func aboutLink(icon: String, title: LocalizedStringKey, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MacSettingsView()
        .environment(TranslationService())
        .frame(minWidth: 500, minHeight: 400)
}
