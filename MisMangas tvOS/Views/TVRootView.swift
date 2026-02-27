//
//  TVRootView.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI
import SwiftData

struct TVRootView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    @Query private var localCollection: [UserCollection]

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
                TVCollectionView(cloudVM: cloudVM)
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
                    // Sincronizar local a cloud al hacer login
                    await syncLocalToCloud()
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

    // MARK: - Sync Local to Cloud

    private func syncLocalToCloud() async {
        let syncVM = SyncViewModel(authVM: authVM)
        syncVM.setModelContainer(modelContext.container)
        await syncVM.syncLocalToCloud(localCollection)
    }
}

// MARK: - Login Prompt View

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

// MARK: - Previews

#Preview("Root View") {
    let authVM = AuthViewModel()
    TVRootView()
        .environment(authVM)
        .environment(CloudCollectionViewModel(authVM: authVM))
        .environment(TranslationService())
        .modelContainer(for: [MangaModel.self, UserCollection.self, OwnedVolume.self], inMemory: true)
}

#Preview("Login Prompt") {
    TVLoginPromptView()
        .environment(AuthViewModel())
}
