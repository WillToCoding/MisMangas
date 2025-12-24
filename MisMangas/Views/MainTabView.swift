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

    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("tab_explore", systemImage: "magnifyingglass")
                }

            CollectionView()
                .tabItem {
                    Label("tab_collection", systemImage: "books.vertical.fill")
                }

            ProfileView()
                .tabItem {
                    Label("tab_profile", systemImage: "person.circle")
                }
        }
        .alert("session_expired_title", isPresented: .init(
            get: { authVM.showSessionExpiredAlert },
            set: { authVM.showSessionExpiredAlert = $0 }
        )) {
            Button("action_ok", role: .cancel) { }
        } message: {
            Text("session_expired_message")
        }
        .task {
            await authVM.checkAndRenewTokenIfNeeded()
        }
    }
}

#Preview {
    let authVM = AuthViewModel()
    let cloudVM = CloudCollectionViewModel(authVM: authVM)
    return MainTabView()
        .environment(authVM)
        .environment(cloudVM)
        .modelContainer(.preview)
}
