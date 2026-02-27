//
//  MacCollectionView.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI
import SwiftData

struct MacCollectionView: View {
    @Binding var selection: Manga?

    @Query(sort: \UserCollection.addedDate, order: .reverse) private var localCollection: [UserCollection]
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    @State private var showDeleteAlert = false
    @State private var mangaToDelete: Int?
    @State private var collectionItemToEdit: UserMangaCollection?
    @State private var localItemToEdit: UserCollection?

    // MARK: - Stats Computed Properties

    private var totalMangas: Int {
        authVM.isAuthenticated ? cloudVM.cloudCollection.count : localCollection.count
    }

    private var completedMangas: Int {
        if authVM.isAuthenticated {
            return cloudVM.cloudCollection.filter { $0.completeCollection }.count
        } else {
            return localCollection.filter { $0.hasCompleteCollection }.count
        }
    }

    private var overallProgress: Int {
        if authVM.isAuthenticated {
            let items = cloudVM.cloudCollection.compactMap { item -> (current: Int, total: Int)? in
                guard let total = item.manga.volumes, total > 0 else { return nil }
                return (item.readingVolume ?? 0, total)
            }
            guard !items.isEmpty else { return 0 }
            let totalRead = items.reduce(0) { $0 + $1.current }
            let totalVolumes = items.reduce(0) { $0 + $1.total }
            return totalVolumes > 0 ? Int((Double(totalRead) / Double(totalVolumes)) * 100) : 0
        } else {
            let items = localCollection.compactMap { item -> (current: Int, total: Int)? in
                guard let total = item.totalVolumes, total > 0 else { return nil }
                return (item.currentReadingVolume ?? 0, total)
            }
            guard !items.isEmpty else { return 0 }
            let totalRead = items.reduce(0) { $0 + $1.current }
            let totalVolumes = items.reduce(0) { $0 + $1.total }
            return totalVolumes > 0 ? Int((Double(totalRead) / Double(totalVolumes)) * 100) : 0
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                if totalMangas > 0 {
                    MacStatsHeader(
                        totalMangas: totalMangas,
                        completedMangas: completedMangas,
                        overallProgress: overallProgress,
                        isCloud: authVM.isAuthenticated
                    )
                    .padding(.horizontal)
                }

                if authVM.isAuthenticated {
                    cloudCollectionContent
                } else {
                    localCollectionContent
                }

                Spacer(minLength: 50)
            }
            .padding(.vertical)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("nav_collection")
        .toolbar { toolbarContent }
        .task {
            if authVM.isAuthenticated {
                await cloudVM.loadCollection()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshContent)) { _ in
            if authVM.isAuthenticated {
                Task { await cloudVM.loadCollection() }
            }
        }
        .alert("collection_delete_title", isPresented: $showDeleteAlert) {
            Button("action_cancel", role: .cancel) { }
            Button("action_delete", role: .destructive) {
                if let mangaId = mangaToDelete {
                    Task { try? await cloudVM.removeFromCollection(mangaId: mangaId) }
                }
            }
        } message: {
            Text("collection_delete_message")
        }
        .sheet(item: $collectionItemToEdit) { item in
            MacEditCollectionView(collectionItem: item)
        }
        .sheet(item: $localItemToEdit) { item in
            MacEditLocalCollectionView(collection: item)
        }
        .overlay {
            if cloudVM.state.isLoading {
                ProgressView("loading_collection")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem {
            if authVM.isAuthenticated {
                Image(systemName: "cloud.fill")
                    .foregroundStyle(.blue)
            }
        }

        ToolbarItem {
            Button {
                Task {
                    if authVM.isAuthenticated {
                        await cloudVM.loadCollection()
                    }
                }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("action_refresh")
        }
    }

    // MARK: - Cloud Collection Content

    private var cloudCollectionContent: some View {
        Group {
            if cloudVM.cloudCollection.isEmpty && !cloudVM.state.isLoading {
                emptyStateView
            } else {
                ForEach(DemographicsConfig.list) { config in
                    let mangas = cloudVM.cloudCollection.filter { item in
                        item.manga.demographics.contains { $0.demographic == config.id }
                    }
                    if !mangas.isEmpty {
                        collectionSection(title: config.title, icon: config.icon, color: config.color, items: mangas)
                    }
                }

                let otherMangas = cloudVM.cloudCollection.filter { $0.manga.demographics.isEmpty }
                if !otherMangas.isEmpty {
                    collectionSection(title: "section_other", icon: "square.grid.2x2", color: .gray, items: otherMangas)
                }
            }
        }
    }

    // MARK: - Local Collection Content

    private var localCollectionContent: some View {
        Group {
            if localCollection.isEmpty {
                emptyStateView
            } else {
                ForEach(DemographicsConfig.list) { config in
                    let items = localCollection.filter { $0.manga.demographicNames.contains(config.id) }
                    if !items.isEmpty {
                        localCollectionSection(title: config.title, icon: config.icon, color: config.color, items: items)
                    }
                }

                let otherItems = localCollection.filter { $0.manga.demographicNames.isEmpty }
                if !otherItems.isEmpty {
                    localCollectionSection(title: "section_other", icon: "square.grid.2x2", color: .gray, items: otherItems)
                }
            }
        }
    }

    // MARK: - Section Builders

    private func collectionSection(
        title: LocalizedStringKey,
        icon: String,
        color: Color,
        items: [UserMangaCollection]
    ) -> some View {
        MacHorizontalSection(title: title, icon: icon, color: color, itemCount: items.count) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                MacCollectionCard(manga: item.manga, item: item)
                    .id(index)
                    .onTapGesture { selection = item.manga }
                    .contextMenu {
                        Button { collectionItemToEdit = item } label: {
                            Label("action_edit", systemImage: "pencil")
                        }
                        Divider()
                        Button("action_delete", role: .destructive) {
                            mangaToDelete = item.manga.id
                            showDeleteAlert = true
                        }
                    }
            }
        }
    }

    private func localCollectionSection(
        title: LocalizedStringKey,
        icon: String,
        color: Color,
        items: [UserCollection]
    ) -> some View {
        MacHorizontalSection(title: title, icon: icon, color: color, itemCount: items.count) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                MacLocalCollectionCard(collection: item)
                    .id(index)
                    .onTapGesture { selection = item.manga.toManga() }
                    .contextMenu {
                        Button { localItemToEdit = item } label: {
                            Label("action_edit", systemImage: "pencil")
                        }
                        Divider()
                        Button("action_delete", role: .destructive) {
                            Task {
                                let dataContainer = DataContainer(modelContainer: modelContext.container)
                                try? await dataContainer.removeFromCollection(mangaId: item.manga.id)
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView(
            "collection_empty_title",
            systemImage: "books.vertical",
            description: Text("collection_empty_description")
        )
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

#Preview(traits: .sampleData) {
    @Previewable @State var selection: Manga? = nil
    MacCollectionView(selection: $selection)
}
