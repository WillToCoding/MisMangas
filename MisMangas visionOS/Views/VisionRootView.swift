//
//  VisionRootView.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

enum VisionNavigationItem: String, CaseIterable, Identifiable {
    case explore
    case bestMangas
    case collection

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .explore: return "nav_explore"
        case .bestMangas: return "best_mangas_title"
        case .collection: return "nav_collection"
        }
    }

    var icon: String {
        switch self {
        case .explore: return "square.grid.2x2"
        case .bestMangas: return "star.fill"
        case .collection: return "books.vertical"
        }
    }
}

struct VisionRootView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @State private var selectedSection: VisionNavigationItem? = .explore
    @State private var exploreVM = MangaViewModel()
    @State private var bestMangasVM = MangaViewModel()
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

                Section {
                    if authVM.isAuthenticated {
                        Label(authVM.userEmail ?? "Usuario", systemImage: "person.circle.fill")
                            .foregroundStyle(.primary)

                        Button(role: .destructive) {
                            authVM.logout()
                        } label: {
                            Label("action_logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } else {
                        Button {
                            showLogin = true
                        } label: {
                            Label("action_login", systemImage: "person.circle")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("app_name")
        } detail: {
            NavigationStack {
                Group {
                    switch selectedSection {
                    case .explore:
                        VisionExploreView()
                            .environment(exploreVM)
                    case .bestMangas:
                        VisionBestMangasView()
                            .environment(bestMangasVM)
                    case .collection:
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
