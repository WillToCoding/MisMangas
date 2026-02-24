//
//  VisionRootView.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

enum VisionNavigationItem: String, CaseIterable, Identifiable {
    case home
    case collection
    case search
    case profile

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .home: return "tab_home"
        case .collection: return "nav_collection"
        case .search: return "nav_search"
        case .profile: return "nav_profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .collection: return "books.vertical.fill"
        case .search: return "magnifyingglass"
        case .profile: return "person.circle.fill"
        }
    }
}

struct VisionRootView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedSection: VisionNavigationItem? = .home
    @State private var homeVM = HomeViewModel()
    @State private var searchVM = MangaViewModel()
    @State private var showImmersive = false
    @State private var showLogin = false

    var body: some View {
        NavigationSplitView {
            // Sidebar con navegación
            List(selection: $selectedSection) {
                Section {
                    ForEach(VisionNavigationItem.allCases) { item in
                        Label(item.title, systemImage: item.icon)
                            .tag(item)
                    }
                }

                Section {
                    // Modo inmersivo
                    Button {
                        Task {
                            if showImmersive {
                                await dismissImmersiveSpace()
                            } else {
                                await openImmersiveSpace(id: "ImmersiveMangaSpace")
                            }
                            showImmersive.toggle()
                        }
                    } label: {
                        Label(
                            showImmersive ? String(localized: "vision_exit_immersive") : String(localized: "vision_immersive_mode"),
                            systemImage: showImmersive ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
                        )
                    }
                    .disabled(!authVM.isAuthenticated || cloudVM.cloudCollection.isEmpty)
                }
            }
            .navigationTitle("app_name")
        } detail: {
            NavigationStack {
                Group {
                    switch selectedSection {
                    case .home:
                        VisionHomeView(viewModel: homeVM)
                    case .collection:
                        if !authVM.isAuthenticated {
                            VisionLoginPromptView(showLogin: $showLogin)
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
                            VisionCollectionView(cloudVM: cloudVM)
                        }
                    case .search:
                        VisionSearchView()
                            .environment(searchVM)
                    case .profile:
                        VisionProfileView(showLogin: $showLogin)
                    case .none:
                        ContentUnavailableView(
                            "empty_select_section",
                            systemImage: "sidebar.left"
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showLogin) {
            VisionLoginView()
        }
        .task {
            if authVM.isAuthenticated {
                await cloudVM.loadCollection()
            }
        }
        .onChange(of: authVM.isAuthenticated) { _, isAuth in
            if isAuth {
                Task {
                    await cloudVM.loadCollection()
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && authVM.isAuthenticated {
                Task {
                    await cloudVM.loadCollection()
                }
            }
        }
    }
}

struct VisionLoginPromptView: View {
    @Binding var showLogin: Bool

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "vision.pro")
                .font(.system(size: 100))
                .foregroundStyle(.blue)

            Text("vision_welcome")
                .font(.largeTitle.bold())

            Text("vision_welcome_description")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)

            Button {
                showLogin = true
            } label: {
                Text("action_login")
                    .font(.title2.bold())
                    .frame(width: 300)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(60)
    }
}

// MARK: - Vision Profile View
struct VisionProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Binding var showLogin: Bool
    @State private var showLogoutAlert = false
    @State private var showSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // MARK: - Header Perfil
                VStack(spacing: 20) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(.blue)

                    if authVM.isAuthenticated, let email = authVM.userEmail {
                        Text(email)
                            .font(.title.bold())

                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("profile_connected")
                                .foregroundStyle(.secondary)
                        }
                        .font(.title3)
                    } else {
                        Text("profile_not_connected")
                            .font(.title2)
                            .foregroundStyle(.secondary)

                        Text("profile_login_prompt")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(40)
                .frame(maxWidth: .infinity)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))

                // MARK: - Cuenta
                VStack(alignment: .leading, spacing: 20) {
                    Label("profile_account", systemImage: "person.crop.circle.fill")
                        .font(.title2.bold())
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
                            .font(.title3)
                        }
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
                            .font(.title3)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Text(authVM.isAuthenticated ? "profile_storage_cloud" : "profile_storage_local")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(30)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 20))

                // MARK: - Almacenamiento
                VStack(alignment: .leading, spacing: 20) {
                    Label("profile_storage", systemImage: "externaldrive.fill")
                        .font(.title2.bold())
                        .foregroundStyle(.green)

                    HStack {
                        Image(systemName: "cloud.fill")
                            .foregroundStyle(authVM.isAuthenticated ? .blue : .secondary)
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
                    .font(.title3)

                    HStack {
                        Image(systemName: "internaldrive.fill")
                            .foregroundStyle(.green)
                        Text("profile_local_collection")
                        Spacer()
                        Text("profile_session_active")
                            .foregroundStyle(.secondary)
                    }
                    .font(.title3)
                }
                .padding(30)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.green.opacity(0.05), in: RoundedRectangle(cornerRadius: 20))

                // MARK: - Ajustes
                NavigationLink(destination: VisionSettingsView()) {
                    HStack {
                        Label("settings_title", systemImage: "gearshape.fill")
                            .font(.title3.bold())
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(40)
        }
        .navigationTitle("nav_profile")
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

// MARK: - Vision Settings View
struct VisionSettingsView: View {
    @State private var deeplApiKey: String = ""

    @Environment(TranslationService.self) private var translationService
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // MARK: - Traducción (DeepL)
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

                // MARK: - Acerca de
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
                            url: "willtocoding.com/mismangas/privacy"
                        )

                        VisionLinkRow(
                            icon: "doc.text.fill",
                            title: "profile_terms_of_service",
                            url: "willtocoding.com/mismangas/terms"
                        )

                        VisionLinkRow(
                            icon: "accessibility",
                            title: "profile_accessibility",
                            url: "willtocoding.com/mismangas/accessibility"
                        )

                        VisionLinkRow(
                            icon: "envelope.fill",
                            title: "profile_contact",
                            url: "willtocoding.com/mismangas/contact"
                        )
                    }
                }
                .padding(30)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
            }
            .padding(40)
        }
        .navigationTitle("settings_title")
        .onAppear {
            deeplApiKey = translationService.apiKey
        }
    }
}

// MARK: - Vision Link Row
struct VisionLinkRow: View {
    let icon: String
    let title: LocalizedStringKey
    let url: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)

            Text(title)

            Spacer()

            Text(url)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .font(.title3)
    }
}
