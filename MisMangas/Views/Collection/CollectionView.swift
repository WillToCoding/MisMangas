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
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    @Namespace private var namespace
    @State private var showDeleteAlert = false
    @State private var mangaToDelete: Int?

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
                            try? await cloudVM.removeFromCollection(mangaId: mangaId)
                        }
                    }
                }
            } message: {
                Text("collection_delete_message")
            }
        }
    }

    // MARK: - Cloud Collection (por demografía)

    @ViewBuilder
    private var cloudCollectionView: some View {
        if cloudVM.isLoading {
            ProgressView("loading_collection")
        } else if let error = cloudVM.errorMessage {
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
                        let mangas = cloudMangasByDemographic(config.key)
                        if !mangas.isEmpty {
                            section(title: config.title, icon: config.icon, color: config.color, mangas: mangas)
                        }
                    }

                    // Sin demografía
                    let other = cloudMangasWithoutDemographic()
                    if !other.isEmpty {
                        section(title: "section_other", icon: "square.grid.2x2", color: .gray, mangas: other)
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
                        let mangas = localMangasByDemographic(config.key)
                        if !mangas.isEmpty {
                            section(title: config.title, icon: config.icon, color: config.color, mangas: mangas)
                        }
                    }

                    // Sin demografía
                    let other = localMangasWithoutDemographic()
                    if !other.isEmpty {
                        section(title: "section_other", icon: "square.grid.2x2", color: .gray, mangas: other)
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

    // MARK: - Section

    private func section(title: LocalizedStringKey, icon: String, color: Color, mangas: [Manga]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.title3.bold())
                    .foregroundStyle(color)

                Text("(\(mangas.count))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(mangas) { manga in
                        NavigationLink(value: manga) {
                            MangaCard(manga: manga, namespace: namespace)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Grouping (Cloud)

    private func cloudMangasByDemographic(_ demographic: String) -> [Manga] {
        cloudVM.cloudCollection
            .filter { $0.manga.demographics.contains { $0.demographic == demographic } }
            .map { $0.manga }
    }

    private func cloudMangasWithoutDemographic() -> [Manga] {
        cloudVM.cloudCollection
            .filter { $0.manga.demographics.isEmpty }
            .map { $0.manga }
    }

    // MARK: - Grouping (Local)

    private func localMangasByDemographic(_ demographic: String) -> [Manga] {
        localCollection
            .filter { $0.manga.demographicNames.contains(demographic) }
            .map { $0.manga.toManga() }
    }

    private func localMangasWithoutDemographic() -> [Manga] {
        localCollection
            .filter { $0.manga.demographicNames.isEmpty }
            .map { $0.manga.toManga() }
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
