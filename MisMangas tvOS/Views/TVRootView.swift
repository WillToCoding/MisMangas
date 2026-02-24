//
//  TVRootView.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct TVRootView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            // Tab 1: Home
            NavigationStack {
                TVHomeView()
            }
            .tabItem {
                Label("nav_home", systemImage: "house.fill")
            }

            // Tab 2: Mi Colección
            NavigationStack {
                Group {
                    if !authVM.isAuthenticated {
                        TVLoginPromptView()
                    } else if cloudVM.state.isLoading && cloudVM.cloudCollection.isEmpty {
                        ProgressView("loading_collection")
                            .font(.title)
                    } else if cloudVM.cloudCollection.isEmpty {
                        ContentUnavailableView(
                            "collection_empty_title",
                            systemImage: "books.vertical",
                            description: Text("collection_empty_description")
                        )
                    } else {
                        TVCollectionView(cloudVM: cloudVM)
                    }
                }
            }
            .tabItem {
                Label("tab_collection", systemImage: "books.vertical")
            }

            // Tab 3: Perfil
            NavigationStack {
                TVProfileView()
            }
            .tabItem {
                Label("tab_profile", systemImage: "person.circle")
            }

            // Tab 4: Búsqueda
            NavigationStack {
                TVSearchView()
            }
            .tabItem {
                Label("nav_search", systemImage: "magnifyingglass")
            }
        }
        .task {
            if authVM.isAuthenticated {
                await cloudVM.loadCollection()
            }
        }
        .onChange(of: authVM.isAuthenticated) { oldValue, newValue in
            if newValue {
                Task {
                    await cloudVM.loadCollection()
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && authVM.isAuthenticated {
                Task {
                    await cloudVM.loadCollection()
                }
            }
        }
    }
}

struct TVLoginPromptView: View {
    @State private var showLogin = false

    var body: some View {
        VStack(spacing: 60) {
            Image(systemName: "appletvremote.gen1")
                .font(.system(size: 150))
                .foregroundStyle(.blue)

            VStack(spacing: 30) {
                Text("tv_welcome")
                    .font(.system(size: 72, weight: .bold))

                Text("profile_login_prompt")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 1200)
            }

            Button {
                showLogin = true
            } label: {
                Label("action_login", systemImage: "person.circle.fill")
                    .font(.system(size: 36, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(120)
        .sheet(isPresented: $showLogin) {
            TVLoginView()
        }
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

struct TVProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @State private var showLogin = false
    @State private var showLogoutAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 60) {
                // MARK: - Header Perfil
                VStack(spacing: 30) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 150))
                        .foregroundStyle(.blue)

                    if authVM.isAuthenticated, let email = authVM.userEmail {
                        Text(email)
                            .font(.system(size: 40, weight: .semibold))

                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("profile_connected")
                                .foregroundStyle(.secondary)
                        }
                        .font(.system(size: 28))
                    } else {
                        Text("profile_not_connected")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)

                        Text("profile_login_prompt")
                            .font(.system(size: 28))
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(50)
                .frame(maxWidth: .infinity)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 24))

                // MARK: - Cuenta
                VStack(alignment: .leading, spacing: 24) {
                    Label("profile_account", systemImage: "person.crop.circle.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.blue)

                    if authVM.isAuthenticated {
                        Button {
                            showLogoutAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("action_logout")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            showLogin = true
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.key.fill")
                                Text("action_login")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.system(size: 28, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Text(authVM.isAuthenticated ? "profile_storage_cloud" : "profile_storage_local")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                }
                .padding(40)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 24))
                .focusSection()

                // MARK: - Almacenamiento
                VStack(alignment: .leading, spacing: 24) {
                    Label("profile_storage", systemImage: "externaldrive.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.green)

                    HStack {
                        Image(systemName: "cloud.fill")
                            .foregroundStyle(authVM.isAuthenticated ? .blue : .secondary)
                            .font(.system(size: 28))
                        Text("profile_cloud_collection")
                            .font(.system(size: 28))
                        Spacer()
                        if authVM.isAuthenticated {
                            Text("\(cloudVM.cloudCollection.count) mangas")
                                .font(.system(size: 24))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("-")
                                .font(.system(size: 24))
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        Image(systemName: "internaldrive.fill")
                            .foregroundStyle(.green)
                            .font(.system(size: 28))
                        Text("profile_local_collection")
                            .font(.system(size: 28))
                        Spacer()
                        Text("profile_session_active")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(40)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.green.opacity(0.05), in: RoundedRectangle(cornerRadius: 24))

                // MARK: - Ajustes
                NavigationLink(destination: TVSettingsView()) {
                    HStack {
                        Label("settings_title", systemImage: "gearshape.fill")
                            .font(.system(size: 32, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                    .padding(30)
                    .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .focusSection()

                Spacer(minLength: 50)
            }
            .padding(80)
        }
        .navigationTitle("tab_profile")
        .sheet(isPresented: $showLogin) {
            TVLoginView()
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
}

// MARK: - TV Settings View
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

                // MARK: - Acerca de
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
}
