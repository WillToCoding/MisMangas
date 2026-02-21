//
//  ProfileView.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var showLoginSheet = false
    @State private var showLogoutAlert = false
    @State private var deeplApiKey: String = ""

    private let translationService = TranslationService.shared

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Sección de Usuario
                Section {
                    if authVM.isAuthenticated {
                        // Usuario logueado
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.blue)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading) {
                                Text("profile_connected")
                                    .font(.headline)
                                if let email = authVM.userEmail {
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .accessibilityHidden(true)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(String(localized: "accessibility_user_connected") + ", " + (authVM.userEmail ?? ""))
                    } else {
                        // Usuario NO logueado
                        HStack {
                            Image(systemName: "person.circle")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading) {
                                Text("profile_not_connected")
                                    .font(.headline)
                                Text("profile_login_prompt")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(String(localized: "accessibility_user_not_connected"))
                    }
                } header: {
                    Text("profile_account")
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                }

                // MARK: - Colección
                Section {
                    HStack {
                        Image(systemName: "cloud.fill")
                            .foregroundStyle(authVM.isAuthenticated ? .blue : .secondary)
                            .accessibilityHidden(true)
                        Text("profile_cloud_collection")
                        Spacer()
                        Text(authVM.isAuthenticated ? String(localized: "profile_session_active") : "-")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(String(localized: "accessibility_cloud_storage") + ": " + (authVM.isAuthenticated ? String(localized: "profile_session_active") : String(localized: "accessibility_inactive")))

                    HStack {
                        Image(systemName: "internaldrive.fill")
                            .foregroundStyle(.green)
                            .accessibilityHidden(true)
                        Text("profile_local_collection")
                        Spacer()
                        Text("profile_session_active")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(String(localized: "accessibility_local_storage") + ": " + String(localized: "profile_session_active"))
                } header: {
                    Text("profile_storage")
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                } footer: {
                    if authVM.isAuthenticated {
                        Text("profile_storage_cloud")
                    } else {
                        Text("profile_storage_local")
                    }
                }

                // MARK: - Traducción
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundStyle(.blue)
                                .accessibilityHidden(true)
                            Text("translation_settings_title")
                        }

                        SecureField("translation_settings_api_key_placeholder", text: $deeplApiKey)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onChange(of: deeplApiKey) { _, newValue in
                                translationService.apiKey = newValue
                            }
                            .accessibilityLabel(String(localized: "accessibility_api_key_field"))
                            .accessibilityHint(String(localized: "accessibility_api_key_hint"))

                        if translationService.isConfigured {
                            Label("translation_settings_configured", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                } header: {
                    Text("translation_settings_header")
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                } footer: {
                    Text("translation_settings_footer")
                }

                // MARK: - Acciones
                Section {
                    if authVM.isAuthenticated {
                        Button(role: .destructive) {
                            showLogoutAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .accessibilityHidden(true)
                                Text("action_logout")
                            }
                        }
                        .accessibilityHint(String(localized: "accessibility_logout_hint"))
                    } else {
                        Button {
                            showLoginSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.key.fill")
                                    .accessibilityHidden(true)
                                Text("action_login")
                            }
                        }
                        .accessibilityHint(String(localized: "accessibility_login_hint"))
                    }
                }
            }
            .navigationTitle("nav_profile")
            .sheet(isPresented: $showLoginSheet) {
                LoginView()
            }
            .alert("profile_logout_title", isPresented: $showLogoutAlert) {
                Button("action_cancel", role: .cancel) { }
                Button("action_logout", role: .destructive) {
                    authVM.logout()
                }
            } message: {
                Text("profile_logout_message")
            }
            .onAppear {
                deeplApiKey = translationService.apiKey
            }
        }
    }
}

// MARK: - Preview
#Preview("No autenticado") {
    @Previewable @State var authVM = AuthViewModel()
    ProfileView()
        .environment(authVM)
}

#Preview("Autenticado") {
    @Previewable @State var authVM = AuthViewModel()
    ProfileView()
        .environment(authVM)
        .onAppear {
            authVM.isAuthenticated = true
            authVM.userEmail = "test@example.com"
        }
}
