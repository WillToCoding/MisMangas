//
//  CollectionView.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI
import SwiftData

struct CollectionView: View {
    @Query(sort: \UserCollection.addedDate, order: .reverse) private var localCollection: [UserCollection]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    @Namespace private var namespace
    @State private var showDeleteAlert = false
    @State private var mangaToDelete: Int?
    @State private var showConflictsSheet = false
    @State private var collectionItemToEdit: UserMangaCollection?
    @State private var localItemToEdit: UserCollection?

    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    private let demographicConfig: [(key: String, title: LocalizedStringKey, icon: String, color: Color)] = [
        ("Shounen", "section_shounen", "flame.fill", .orange),
        ("Seinen", "section_seinen", "person.fill", .purple),
        ("Shoujo", "section_shoujo", "heart.fill", .pink),
        ("Josei", "section_josei", "sparkles", .indigo),
        ("Kids", "section_kids", "star.fill", .yellow)
    ]

    var body: some View {
        NavigationStack {
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
            .sheet(isPresented: $showConflictsSheet) {
                SyncConflictView()
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
            .onChange(of: cloudVM.hasConflicts) { _, hasConflicts in
                if hasConflicts {
                    showConflictsSheet = true
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
    }

    // MARK: - Cloud Collection (por demografía)

    @ViewBuilder
    private var cloudCollectionView: some View {
        if cloudVM.state.isLoading {
            ProgressView("loading_collection")
        } else if let error = cloudVM.state.errorMessage {
            ContentUnavailableView(
                "error_loading",
                systemImage: "exclamationmark.triangle",
                description: Text(error)
            )
        } else if cloudVM.cloudCollection.isEmpty {
            emptyStateView
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    // Stats
                    collectionStats(count: cloudVM.cloudCollection.count, isCloud: true)

                    // Secciones por demografía
                    ForEach(demographicConfig, id: \.key) { config in
                        let items = cloudItemsByDemographic(config.key)
                        if !items.isEmpty {
                            cloudSection(title: config.title, icon: config.icon, color: config.color, items: items)
                        }
                    }

                    // Sin demografía
                    let other = cloudItemsWithoutDemographic()
                    if !other.isEmpty {
                        cloudSection(title: "section_other", icon: "square.grid.2x2", color: .gray, items: other)
                    }

                    Spacer(minLength: 50)
                }
                .padding(.top)
            }
        }
    }

    // MARK: - Local Collection (por demografía)

    @ViewBuilder
    private var localCollectionView: some View {
        if localCollection.isEmpty {
            emptyStateView
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    // Stats
                    collectionStats(count: localCollection.count, isCloud: false)

                    // Secciones por demografía
                    ForEach(demographicConfig, id: \.key) { config in
                        let items = localItemsByDemographic(config.key)
                        if !items.isEmpty {
                            localSection(title: config.title, icon: config.icon, color: config.color, items: items)
                        }
                    }

                    // Sin demografía
                    let other = localItemsWithoutDemographic()
                    if !other.isEmpty {
                        localSection(title: "section_other", icon: "square.grid.2x2", color: .gray, items: other)
                    }

                    Spacer(minLength: 50)
                }
                .padding(.top)
            }
        }
    }

    // MARK: - Stats Header

    private func collectionStats(count: Int, isCloud: Bool) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(count)")
                    .font(.largeTitle.bold())
                Text("collection_total_mangas")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isCloud {
                Label("collection_cloud_label", systemImage: "cloud.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Cloud Section

    private func cloudSection(title: LocalizedStringKey, icon: String, color: Color, items: [UserMangaCollection]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.title3.bold())
                    .foregroundStyle(color)

                Text("(\(items.count))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(items) { item in
                        NavigationLink(value: item.manga) {
                            MangaCard(manga: item.manga, namespace: namespace)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                collectionItemToEdit = item
                            } label: {
                                Label("action_edit", systemImage: "pencil")
                            }

                            Divider()

                            Button(role: .destructive) {
                                mangaToDelete = item.manga.id
                                showDeleteAlert = true
                            } label: {
                                Label("action_delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Local Section

    private func localSection(title: LocalizedStringKey, icon: String, color: Color, items: [UserCollection]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.title3.bold())
                    .foregroundStyle(color)

                Text("(\(items.count))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(items) { item in
                        NavigationLink(value: item.manga.toManga()) {
                            MangaCard(manga: item.manga.toManga(), namespace: namespace)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                localItemToEdit = item
                            } label: {
                                Label("action_edit", systemImage: "pencil")
                            }

                            Divider()

                            Button(role: .destructive) {
                                mangaToDelete = item.manga.id
                                showDeleteAlert = true
                            } label: {
                                Label("action_delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Grouping (Cloud)

    private func cloudItemsByDemographic(_ demographic: String) -> [UserMangaCollection] {
        cloudVM.cloudCollection
            .filter { $0.manga.demographics.contains { $0.demographic == demographic } }
    }

    private func cloudItemsWithoutDemographic() -> [UserMangaCollection] {
        cloudVM.cloudCollection
            .filter { $0.manga.demographics.isEmpty }
    }

    // MARK: - Grouping (Local)

    private func localItemsByDemographic(_ demographic: String) -> [UserCollection] {
        localCollection
            .filter { $0.manga.demographicNames.contains(demographic) }
    }

    private func localItemsWithoutDemographic() -> [UserCollection] {
        localCollection
            .filter { $0.manga.demographicNames.isEmpty }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
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
