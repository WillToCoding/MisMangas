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
            // Tab 1: Colección
            NavigationStack {
                Group {
                    if !authVM.isAuthenticated {
                        TVLoginPromptView()
                    } else if cloudVM.isLoading && cloudVM.cloudCollection.isEmpty {
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

            // Tab 2: Perfil
            NavigationStack {
                TVProfileView()
            }
            .tabItem {
                Label("tab_profile", systemImage: "person.circle")
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

struct TVProfileView: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        VStack(spacing: 40) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 200))
                .foregroundStyle(.blue)

            if authVM.isAuthenticated, let email = authVM.userEmail {
                Text(email)
                    .font(.system(size: 48, weight: .semibold))

                Button {
                    authVM.logout()
                } label: {
                    Label("action_logout", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 32, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.red)
            } else {
                Text("profile_not_connected")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(120)
    }
}
