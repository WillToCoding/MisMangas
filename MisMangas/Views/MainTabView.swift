//
//  MainTabView.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI
import SwiftData

enum AppTab: Int {
    case home = 0
    case collection = 1
    case profile = 2
    case search = 3
}

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab: AppTab = .home
    @State private var pendingMangaId: Int?

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Inicio
            Tab(value: .home) {
                HomeView()
            } label: {
                Label("tab_home", systemImage: "house")
                    .symbolVariant(.fill)
                    .symbolRenderingMode(.hierarchical)
            }

            // Tab 2: Coleccion
            Tab(value: .collection) {
                CollectionView(pendingMangaId: $pendingMangaId)
            } label: {
                Label("tab_collection", systemImage: "books.vertical")
                    .symbolVariant(.fill)
                    .symbolRenderingMode(.hierarchical)
            }

            // Tab 3: Perfil
            Tab(value: .profile) {
                ProfileView()
            } label: {
                Label("tab_profile", systemImage: "person.circle")
                    .symbolVariant(.fill)
                    .symbolRenderingMode(.hierarchical)
            }

            // Tab 4: Busqueda (al final)
            Tab(value: .search) {
                SearchResultsView()
            } label: {
                Label("nav_search", systemImage: "magnifyingglass")
            }
        }
        .tint(.purple)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewStyle(.sidebarAdaptable)
        .alert("session_expired_title", isPresented: .init(
            get: { authVM.showSessionExpiredAlert },
            set: { authVM.showSessionExpiredAlert = $0 }
        )) {
            Button("action_ok", role: .cancel) { }
        } message: {
            Text("session_expired_message")
        }
        .task {
            // Configurar el ModelContainer para sincronización cloud → local
            let container = modelContext.container
            cloudVM.setModelContainer(container)
            await authVM.checkAndRenewTokenIfNeeded()
        }
        .onOpenURL { url in
            // Deep link desde widget
            if url.host == "collection" {
                selectedTab = .collection
            } else if url.host == "manga",
                      let mangaIdString = url.pathComponents.dropFirst().first,
                      let mangaId = Int(mangaIdString) {
                // mismangas://manga/{id}
                pendingMangaId = mangaId
                selectedTab = .collection
            }
        }
    }
}

#Preview(traits: .sampleData) {
    MainTabView()
}
