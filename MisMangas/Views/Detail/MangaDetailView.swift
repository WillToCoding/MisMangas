//
//  MangaDetailView.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI
import SwiftData

struct MangaDetailView: View {
    let manga: Manga
    let namespace: Namespace.ID

    // MARK: - State
    @State private var viewModel: MangaDetailViewModel
    @State private var showAddToCollection = false

    // MARK: - Environment
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(TranslationService.self) private var translationService
    @Query private var localCollection: [UserCollection]

    // MARK: - Initialization
    init(manga: Manga, namespace: Namespace.ID) {
        self.manga = manga
        self.namespace = namespace
        _viewModel = State(initialValue: MangaDetailViewModel(manga: manga))
    }

    // MARK: - Computed Properties
    private var isInLocalCollection: Bool {
        localCollection.contains { $0.id == manga.id }
    }

    private var isInCloudCollection: Bool {
        cloudVM.isInCollection(manga.id)
    }

    private var userCollectionEntry: UserCollection? {
        localCollection.first { $0.id == manga.id }
    }

    private var collectionStatus: String {
        if authVM.isAuthenticated {
            return isInCloudCollection ? String(localized: "detail_in_cloud") : String(localized: "detail_add_to_cloud")
        } else {
            return isInLocalCollection ? String(localized: "detail_in_collection") : String(localized: "detail_add_to_collection")
        }
    }

    private var collectionIcon: String {
        if authVM.isAuthenticated {
            return isInCloudCollection ? "checkmark.cloud.fill" : "cloud.fill"
        } else {
            return isInLocalCollection ? "checkmark.circle.fill" : "plus.circle.fill"
        }
    }

    private var isInCollection: Bool {
        isInCloudCollection || isInLocalCollection
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header centrado (con stats editables si está en colección)
                DetailHeaderView(
                    manga: manga,
                    namespace: namespace,
                    userCollection: userCollectionEntry
                )
                .padding(.horizontal)

                // Contenido con secciones
                VStack(alignment: .leading, spacing: 20) {
                    // Autores
                    if !manga.authors.isEmpty {
                        DetailAuthorsView(authors: manga.authors)
                    }

                    // Tags en grupo
                    if !manga.genres.isEmpty || !manga.themes.isEmpty || !manga.demographics.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            DetailTagsSection(genres: manga.genres)
                            DetailTagsSection(themes: manga.themes)
                            DetailTagsSection(demographics: manga.demographics)
                        }
                    }

                    // Personajes
                    DetailCharactersView(
                        characters: viewModel.characters,
                        isLoading: viewModel.isLoadingCharacters
                    )

                    // Relacionados
                    DetailRelatedView(
                        relatedMangas: viewModel.relatedMangas,
                        relatedMangaDetails: viewModel.relatedMangaDetails,
                        recommendations: viewModel.recommendations,
                        isLoading: viewModel.isLoadingRelated,
                        onMangaTap: viewModel.loadAndNavigateToManga
                    )

                    // Sinopsis
                    if manga.sypnosis != nil || manga.background != nil {
                        DetailSynopsisView(
                            synopsis: manga.sypnosis,
                            background: manga.background,
                            translatedSynopsis: viewModel.translatedSynopsis,
                            translatedBackground: viewModel.translatedBackground,
                            isTranslating: viewModel.isTranslating,
                            showOriginal: viewModel.showOriginal,
                            canTranslate: viewModel.canTranslate,
                            onToggleTranslation: viewModel.toggleTranslation
                        )
                    }

                    // Fechas
                    if manga.startDate != nil || manga.endDate != nil {
                        DetailDatesView(
                            startDate: manga.startDate,
                            endDate: manga.endDate
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("nav_detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(collectionStatus, systemImage: collectionIcon) {
                    showAddToCollection = true
                }
                .foregroundStyle(isInCollection ? .green : .blue)
                .accessibilityLabel(collectionStatus)
                .accessibilityHint(isInCollection ? String(localized: "accessibility_view_collection") : String(localized: "accessibility_add_collection_hint"))
            }
        }
        .sheet(isPresented: $showAddToCollection) {
            AddToCollectionView(manga: manga)
        }
        .navigationDestination(item: $viewModel.selectedRelatedManga) { manga in
            MangaDetailView(manga: manga, namespace: namespace)
        }
        .task(id: manga.id) {
            viewModel.configure(translationService: translationService)
            await viewModel.loadAllData()
        }
    }
}

#Preview(traits: .sampleData) {
    @Previewable @Namespace var namespace
    NavigationStack {
        MangaDetailView(manga: .test, namespace: namespace)
    }
}
