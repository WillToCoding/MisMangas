//
//  CollectionViewiPad.swift
//  MisMangas
//
//  Created by Juan Carlos on 2/2/26.
//

import SwiftUI
import SwiftData

struct CollectionViewiPad: View {
    @Query(sort: \UserCollection.addedDate, order: .reverse) private var localCollection: [UserCollection]
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    @Namespace private var namespace
    @State private var selectedManga: Manga?
    @State private var showDeleteAlert = false
    @State private var mangaToDelete: Int?

    var body: some View {
        NavigationSplitView {
            Group {
                if authVM.isAuthenticated {
                    cloudSidebar
                } else {
                    localSidebar
                }
            }
            .navigationTitle("nav_collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("nav_collection")
                        .font(.title3)
                        .bold()
                }

                if authVM.isAuthenticated && !cloudVM.cloudCollection.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Label("collection_cloud_label", systemImage: "cloud.fill")
                            .foregroundStyle(.blue)
                            .font(.caption)
                            .accessibilityLabel(String(localized: "accessibility_cloud_synced"))
                    }
                }
            }
            .toolbarRole(.editor)
        } detail: {
            if let selectedManga {
                MangaDetailView(manga: selectedManga, namespace: namespace)
            } else {
                ContentUnavailableView(
                    "collection_select_manga",
                    systemImage: "book.closed",
                    description: Text("collection_select_manga_description")
                )
            }
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
                        try? await cloudVM.removeFromCollection(mangaId: mangaId)
                    }
                }
            }
        } message: {
            Text("collection_delete_message")
        }
    }

    // MARK: - Cloud Sidebar
    private var cloudSidebar: some View {
        Group {
            if cloudVM.state.isLoading {
                ProgressView("loading_collection")
            } else if let error = cloudVM.state.errorMessage {
                ContentUnavailableView(
                    "error_loading",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if cloudVM.cloudCollection.isEmpty {
                ContentUnavailableView(
                    "collection_empty_title",
                    systemImage: "books.vertical",
                    description: Text("collection_empty_description")
                )
            } else {
                List(selection: $selectedManga) {
                    ForEach(cloudVM.cloudCollection) { item in
                        CollectionRow(item: item)
                            .tag(item.manga)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    mangaToDelete = item.manga.id
                                    showDeleteAlert = true
                                } label: {
                                    Label("action_delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Local Sidebar
    private var localSidebar: some View {
        Group {
            if localCollection.isEmpty {
                ContentUnavailableView(
                    "collection_empty_title",
                    systemImage: "books.vertical",
                    description: Text("collection_empty_description")
                )
            } else {
                List(selection: $selectedManga) {
                    ForEach(localCollection) { item in
                        CollectionRow(item: item)
                            .tag(item.manga.toManga())
                    }
                    .onDelete(perform: deleteLocalMangas)
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Actions
    private func deleteLocalMangas(at offsets: IndexSet) {
        Task {
            let dataContainer = DataContainer(modelContainer: modelContext.container)
            for index in offsets {
                let mangaId = localCollection[index].manga.id
                try? await dataContainer.removeFromCollection(mangaId: mangaId)
            }
        }
    }
}

#Preview(traits: .sampleData) {
    CollectionViewiPad()
}
