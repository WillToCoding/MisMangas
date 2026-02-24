//
//  MainTabView.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            // Tab 1: Inicio
            Tab {
                HomeView()
            } label: {
                Label("tab_home", systemImage: "house")
                    .symbolVariant(.fill)
                    .symbolRenderingMode(.hierarchical)
            }

            // Tab 2: Coleccion
            Tab {
                CollectionView()
            } label: {
                Label("tab_collection", systemImage: "books.vertical")
                    .symbolVariant(.fill)
                    .symbolRenderingMode(.hierarchical)
            }

            // Tab 3: Perfil
            Tab {
                ProfileView()
            } label: {
                Label("tab_profile", systemImage: "person.circle")
                    .symbolVariant(.fill)
                    .symbolRenderingMode(.hierarchical)
            }

            // Tab 4: Busqueda (al final)
            Tab {
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
            cloudVM.setModelContainer(modelContext.container)
            await authVM.checkAndRenewTokenIfNeeded()
        }
    }
}

#Preview(traits: .sampleData) {
    MainTabView()
}
