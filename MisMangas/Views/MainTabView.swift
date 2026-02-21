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
                if isiPhone {
                    HomeView()
                } else {
                    ContentViewiPad()
                }
            } label: {
                Label("tab_home", systemImage: "house")
                    .symbolVariant(.fill)
                    .symbolRenderingMode(.hierarchical)
            }

            // Tab 2: Coleccion
            Tab {
                if isiPhone {
                    CollectionView()
                } else {
                    CollectionViewiPad()
                }
            } label: {
                Label("tab_collection", systemImage: "books.vertical")
                    .symbolVariant(.fill)
                    .symbolRenderingMode(.hierarchical)
            }

            // Tab 3: Busqueda
            Tab(role: .search) {
                SearchResultsView()
            }

            // Tab 4: Perfil
            Tab {
                ProfileView()
            } label: {
                Label("tab_profile", systemImage: "person.circle")
                    .symbolVariant(.fill)
                    .symbolRenderingMode(.hierarchical)
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
