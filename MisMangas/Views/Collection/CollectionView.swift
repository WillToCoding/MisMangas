//
//  CollectionView.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI
import SwiftData

struct CollectionView: View {
    @Query(sort: \UserCollection.addedDate, order: .reverse) var localCollection: [UserCollection]
    @Environment(\.modelContext) var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AuthViewModel.self) var authVM
    @Environment(CloudCollectionViewModel.self) var cloudVM

    @Binding var pendingMangaId: Int?
    @State private var navigationPath = NavigationPath()
    @Namespace var namespace
    @State var showDeleteAlert = false
    @State var mangaToDelete: Int?
    @State var collectionItemToEdit: UserMangaCollection?
    @State var localItemToEdit: UserCollection?

    init(pendingMangaId: Binding<Int?> = .constant(nil)) {
        self._pendingMangaId = pendingMangaId
    }

    var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if authVM.isAuthenticated {
                    cloudCollectionView
                } else {
                    localCollectionView
                }
            }
            .navigationTitle("nav_collection")
            .navigationDestination(for: Manga.self) { manga in
                MangaDetailView(manga: manga, namespace: namespace)
            }
            .task {
                if authVM.isAuthenticated {
                    await cloudVM.loadCollection()
                }
            }
            .refreshable {
                if authVM.isAuthenticated {
                    await cloudVM.loadCollection()
                }
            }
            .alert("collection_delete_title", isPresented: $showDeleteAlert) {
                Button("action_cancel", role: .cancel) { }
                Button("action_delete", role: .destructive) {
                    if let mangaId = mangaToDelete {
                        Task {
                            if authVM.isAuthenticated {
                                try? await cloudVM.removeFromCollection(mangaId: mangaId)
                            } else {
                                let dataContainer = DataContainer(modelContainer: modelContext.container)
                                try? await dataContainer.removeFromCollection(mangaId: mangaId)
                            }
                        }
                    }
                }
            } message: {
                Text("collection_delete_message")
            }
            .sheet(item: $collectionItemToEdit) { item in
                if isIPad {
                    iPadEditCollectionView(item: item)
                } else {
                    EditReadingVolumeView(item: item)
                }
            }
            .sheet(item: $localItemToEdit) { item in
                if isIPad {
                    iPadEditLocalCollectionView(collection: item)
                } else {
                    EditLocalCollectionView(collection: item)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active && authVM.isAuthenticated {
                    Task {
                        await cloudVM.loadCollection()
                    }
                }
            }
            .onChange(of: pendingMangaId) { _, newValue in
                if let mangaId = newValue, let manga = findManga(by: mangaId) {
                    navigationPath.append(manga)
                    pendingMangaId = nil
                }
            }
        }
    }

    // MARK: - Deep Link Navigation

    private func findManga(by id: Int) -> Manga? {
        if authVM.isAuthenticated {
            return cloudVM.cloudCollection.first { $0.manga.id == id }?.manga
        } else {
            return localCollection.first { $0.manga.id == id }?.manga.toManga()
        }
    }

    // MARK: - Empty State

    var emptyStateView: some View {
        ContentUnavailableView(
            "collection_empty_title",
            systemImage: "books.vertical",
            description: Text("collection_empty_description")
        )
    }
}

#Preview(traits: .sampleData) {
    CollectionView()
}
