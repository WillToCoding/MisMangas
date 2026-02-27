//
//  SettingsView.swift
//  MisMangas
//
//  Created by Juan Carlos on 21/02/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var deeplApiKey: String = ""

    @Environment(TranslationService.self) private var translationService
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Traducción
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundStyle(.blue)
                                .accessibilityHidden(true)
                            Text("translation_settings_title")
                        }

                        #if !os(tvOS) && !os(watchOS)
                        SecureField("translation_settings_api_key_placeholder", text: $deeplApiKey)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            #endif
                            .onChange(of: deeplApiKey) { _, newValue in
                                translationService.apiKey = newValue
                            }
                            .accessibilityLabel(String(localized: "accessibility_api_key_field"))
                            .accessibilityHint(String(localized: "accessibility_api_key_hint"))
                        #endif

                        if translationService.isConfigured {
                            Label("translation_settings_configured", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                } header: {
                    Text("translation_settings_header")
                        .accessibilityHeader(.h2)
                } footer: {
                    Text("translation_settings_footer")
                }

                // MARK: - Acerca de
                Section {
                    // Versión
                    HStack {
                        Text("profile_version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(String(localized: "profile_version") + " " + appVersion)

                    // Ver Onboarding
                    NavigationLink {
                        OnboardingView()
                    } label: {
                        HStack {
                            Image(systemName: "hand.wave.fill")
                                .foregroundStyle(.blue)
                                .accessibilityHidden(true)
                            Text("profile_view_onboarding")
                        }
                    }
                    .accessibilityHint(String(localized: "profile_view_onboarding_hint"))

                    // Política de Privacidad
                    Link(destination: URL(string: "https://www.willtocoding.com/projects/mismangas/privacy")!) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundStyle(.blue)
                                .accessibilityHidden(true)
                            Text("profile_privacy_policy")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityHint(String(localized: "accessibility_opens_safari"))

                    // Términos de Servicio
                    Link(destination: URL(string: "https://www.willtocoding.com/projects/mismangas/terms")!) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(.blue)
                                .accessibilityHidden(true)
                            Text("profile_terms_of_service")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityHint(String(localized: "accessibility_opens_safari"))

                    // Accesibilidad
                    Link(destination: URL(string: "https://www.willtocoding.com/projects/mismangas/accessibility")!) {
                        HStack {
                            Image(systemName: "accessibility")
                                .foregroundStyle(.blue)
                                .accessibilityHidden(true)
                            Text("profile_accessibility")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityHint(String(localized: "accessibility_opens_safari"))

                    // Contacto
                    Link(destination: URL(string: "https://www.willtocoding.com/projects/mismangas/contact")!) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.blue)
                                .accessibilityHidden(true)
                            Text("profile_contact")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityHint(String(localized: "accessibility_opens_safari"))
                } header: {
                    Text("profile_about")
                        .accessibilityHeader(.h2)
                }
            }
            .navigationTitle("settings_title")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(String(localized: "action_close"))
                }
            }
            .onAppear {
                deeplApiKey = translationService.apiKey
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environment(TranslationService())
}
