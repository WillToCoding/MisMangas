//
//  VisionRootView.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI
import SwiftData

enum VisionNavigationItem: String, CaseIterable, Identifiable {
    case home
    case collection
    case profile
    case search

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
    @Environment(\.modelContext) private var modelContext

    @Query private var localCollection: [UserCollection]

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
                        if authVM.isAuthenticated {
                            if cloudVM.state.isLoading && cloudVM.cloudCollection.isEmpty {
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
                        } else {
                            VisionLocalCollectionView()
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
                    // Sincronizar local a cloud al hacer login
                    await syncLocalToCloud()
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

    // MARK: - Sync Local to Cloud

    private func syncLocalToCloud() async {
        let syncVM = SyncViewModel(authVM: authVM)
        syncVM.setModelContainer(modelContext.container)
        await syncVM.syncLocalToCloud(localCollection)
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

#Preview {
    let authVM = AuthViewModel()
    VisionRootView()
        .environment(authVM)
        .environment(CloudCollectionViewModel(authVM: authVM))
}

#Preview("Login Prompt") {
    @Previewable @State var showLogin = false
    VisionLoginPromptView(showLogin: $showLogin)
}

