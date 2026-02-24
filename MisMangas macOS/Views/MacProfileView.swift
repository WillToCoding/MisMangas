//
//  MacProfileView.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 22/2/26.
//

import SwiftUI

struct MacProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @State private var showLoginSheet = false
    @State private var showLogoutAlert = false
    @State private var showSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Header del Perfil
                profileHeader
                    .padding(.top, 20)

                // MARK: - Cuenta
                accountSection

                // MARK: - Almacenamiento
                storageSection

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 40)
        }
        .frame(minWidth: 400)
        .navigationTitle("nav_profile")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
        .sheet(isPresented: $showLoginSheet) {
            MacLoginView()
                .frame(minWidth: 400, minHeight: 300)
        }
        .sheet(isPresented: $showSettings) {
            MacSettingsView()
                .frame(minWidth: 500, minHeight: 400)
        }
        .alert("profile_logout_title", isPresented: $showLogoutAlert) {
            Button("action_cancel", role: .cancel) { }
            Button("action_logout", role: .destructive) {
                authVM.logout()
            }
        } message: {
            Text("profile_logout_message")
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(authVM.isAuthenticated ? .blue : .secondary)

            if authVM.isAuthenticated {
                Text(authVM.userEmail ?? "Usuario")
                    .font(.title2.bold())

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("profile_connected")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            } else {
                Text("profile_not_connected")
                    .font(.title2.bold())

                Text("profile_login_prompt")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Account Section
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("profile_account", systemImage: "person.crop.circle.fill")
                .font(.headline)
                .foregroundStyle(.blue)

            if authVM.isAuthenticated {
                Button(role: .destructive) {
                    showLogoutAlert = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("action_logout")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 12) {
                    Button {
                        showLoginSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.key.fill")
                            Text("action_login")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        showLoginSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("action_register")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Text(authVM.isAuthenticated ? "profile_storage_cloud" : "profile_storage_local")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Storage Section
    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("profile_storage", systemImage: "externaldrive.fill")
                .font(.headline)
                .foregroundStyle(.green)

            HStack {
                Image(systemName: "cloud.fill")
                    .foregroundStyle(authVM.isAuthenticated ? .blue : .secondary)
                    .frame(width: 24)
                Text("profile_cloud_collection")
                Spacer()
                if authVM.isAuthenticated {
                    Text("\(cloudVM.cloudCollection.count) mangas")
                        .foregroundStyle(.secondary)
                } else {
                    Text("-")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)

            Divider()

            HStack {
                Image(systemName: "internaldrive.fill")
                    .foregroundStyle(.green)
                    .frame(width: 24)
                Text("profile_local_collection")
                Spacer()
                Text("profile_session_active")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

}

// MARK: - Mac Settings View
struct MacSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var deeplApiKey: String = ""

    @Environment(TranslationService.self) private var translationService
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        VStack(spacing: 0) {
            // Header
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

            Divider()

            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Traducción
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

                    // MARK: - Acerca de
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

                        Link(destination: URL(string: "https://www.willtocoding.com/proyectos/mismangas/privacy")!) {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                    .frame(width: 20)
                                Text("profile_privacy_policy")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)

                        Link(destination: URL(string: "https://www.willtocoding.com/proyectos/mismangas/terms")!) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .frame(width: 20)
                                Text("profile_terms_of_service")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)

                        Link(destination: URL(string: "https://www.willtocoding.com/proyectos/mismangas/accessibility")!) {
                            HStack {
                                Image(systemName: "accessibility")
                                    .frame(width: 20)
                                Text("profile_accessibility")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)

                        Link(destination: URL(string: "https://www.willtocoding.com/proyectos/mismangas/contact")!) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .frame(width: 20)
                                Text("profile_contact")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(20)
            }
        }
        .onAppear {
            deeplApiKey = translationService.apiKey
        }
    }
}

#Preview {
    MacProfileView()
        .environment(AuthViewModel())
        .environment(CloudCollectionViewModel(authVM: AuthViewModel()))
}
