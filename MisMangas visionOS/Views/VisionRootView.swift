//
//  VisionRootView.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct VisionRootView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @State private var showImmersive = false
    @State private var showLogin = false

    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(alignment: .leading, spacing: 20) {
                if authVM.isAuthenticated {
                    Label(authVM.userEmail ?? "Usuario", systemImage: "person.circle.fill")
                        .font(.headline)

                    Button("action_logout") {
                        authVM.logout()
                    }
                    .foregroundStyle(.red)
                } else {
                    Label("profile_not_connected", systemImage: "person.circle")
                        .foregroundStyle(.secondary)

                    Button("action_login") {
                        showLogin = true
                    }
                    .buttonStyle(.borderedProminent)
                }

                Divider()

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
                .disabled(!authVM.isAuthenticated)

                Spacer()
            }
            .padding()
            .frame(width: 250)
            .navigationTitle("app_name")
        } detail: {
            // Vista principal - Envuelto en NavigationStack para navegación
            NavigationStack {
                if !authVM.isAuthenticated {
                    VisionLoginPromptView(showLogin: $showLogin)
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
                    VisionCollectionView(cloudVM: cloudVM)
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
