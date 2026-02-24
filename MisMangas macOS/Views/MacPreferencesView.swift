//
//  MacPreferencesView.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI
import SwiftData

struct MacPreferencesView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var showLogin = false

    var body: some View {
        TabView {
            // MARK: - General Tab
            GeneralPreferencesView()
                .tabItem {
                    Label("mac_general", systemImage: "gearshape")
                }

            // MARK: - Cuenta Tab
            AccountPreferencesView()
                .tabItem {
                    Label("profile_account", systemImage: "person.circle")
                }

            // MARK: - Traducción Tab
            TranslationPreferencesView()
                .tabItem {
                    Label("translation_settings_header", systemImage: "globe")
                }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - General Preferences
struct GeneralPreferencesView: View {
    @AppStorage("appearanceMode") private var appearanceMode = "auto"
    @AppStorage("defaultSection") private var defaultSection = "explore"

    var body: some View {
        Form {
            Section {
                Picker("mac_appearance", selection: $appearanceMode) {
                    Text("mac_appearance_auto").tag("auto")
                    Text("mac_appearance_light").tag("light")
                    Text("mac_appearance_dark").tag("dark")
                }
                .pickerStyle(.segmented)
            } header: {
                Text("mac_appearance")
                    .font(.headline)
            }

            Divider()

            Section {
                Picker("mac_general", selection: $defaultSection) {
                    Text("nav_explore").tag("explore")
                    Text("best_mangas_title").tag("bestMangas")
                    Text("nav_collection").tag("collection")
                }
            } header: {
                Text("mac_general")
                    .font(.headline)
            }

            Divider()

            Section {
                HStack {
                    Text("mac_version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("mac_build")
                    Spacer()
                    Text("2025.12.11")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("mac_info")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Account Preferences
struct AccountPreferencesView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var showLogin = false

    var body: some View {
        Form {
            Section {
                if authVM.isAuthenticated {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(authVM.userEmail ?? "")
                                .font(.headline)

                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("mac_session_active")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Button("action_logout", role: .destructive) {
                            authVM.logout()
                        }
                        .buttonStyle(.bordered)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("mac_sync")
                            .font(.headline)

                        HStack {
                            Image(systemName: "cloud.fill")
                                .foregroundStyle(.blue)
                            Text("mac_sync_cloud")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("mac_not_logged")
                                    .font(.headline)

                                Text("mac_login_prompt")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button("action_login") {
                            showLogin = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } header: {
                Text("profile_account")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .padding()
        .sheet(isPresented: $showLogin) {
            MacLoginView()
        }
    }
}

// MARK: - Translation Preferences
struct TranslationPreferencesView: View {
    @State private var deeplApiKey: String = ""
    @Environment(TranslationService.self) private var translationService

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "globe")
                            .font(.title2)
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("translation_settings_title")
                                .font(.headline)

                            Text("translation_settings_footer")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("DeepL API Key")
                            .font(.subheadline)

                        SecureField("translation_settings_api_key_placeholder", text: $deeplApiKey)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: deeplApiKey) { _, newValue in
                                translationService.apiKey = newValue
                            }

                        if translationService.isConfigured {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("translation_settings_configured")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }

                    Link(destination: URL(string: "https://www.deepl.com/pro-api")!) {
                        Label("mac_get_api_key", systemImage: "arrow.up.right.square")
                            .font(.caption)
                    }
                }
            } header: {
                Text("translation_settings_header")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            deeplApiKey = translationService.apiKey
        }
    }
}

#Preview {
    MacPreferencesView()
        .environment(AuthViewModel())
        .environment(CloudCollectionViewModel(authVM: AuthViewModel()))
        .modelContainer(.preview)
}
