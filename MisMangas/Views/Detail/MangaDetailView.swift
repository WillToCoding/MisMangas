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
    @State private var showAddToCollection = false
    @State private var characters: [JikanCharacterData] = []
    @State private var isLoadingCharacters = false
    @State private var relatedMangas: [JikanRelation] = []
    @State private var relatedMangaDetails: [Int: Manga] = [:] // Cache de detalles por ID
    @State private var recommendations: [JikanRecommendation] = []
    @State private var isLoadingRelated = false
    @State private var selectedRelatedManga: Manga?
    @State private var isLoadingManga = false
    @State private var translatedSynopsis: String?
    @State private var translatedBackground: String?
    @State private var isTranslating = false
    @State private var showOriginal = false

    // MARK: - Environment
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Query private var localCollection: [UserCollection]

    // MARK: - Services
    private let repository = Network()
    private let translationService = TranslationService.shared

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
                        characters: characters,
                        isLoading: isLoadingCharacters
                    )

                    // Relacionados
                    DetailRelatedView(
                        relatedMangas: relatedMangas,
                        relatedMangaDetails: relatedMangaDetails,
                        recommendations: recommendations,
                        isLoading: isLoadingRelated,
                        onMangaTap: loadAndNavigateToManga
                    )

                    // Sinopsis
                    if manga.sypnosis != nil || manga.background != nil {
                        DetailSynopsisView(
                            synopsis: manga.sypnosis,
                            background: manga.background,
                            translatedSynopsis: translatedSynopsis,
                            translatedBackground: translatedBackground,
                            isTranslating: isTranslating,
                            showOriginal: showOriginal,
                            canTranslate: translationService.isConfigured && translationService.needsTranslation,
                            onToggleTranslation: { showOriginal.toggle() }
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
        .navigationDestination(item: $selectedRelatedManga) { manga in
            MangaDetailView(manga: manga, namespace: namespace)
        }
        .task(id: manga.id) {
            await loadAllData()
        }
    }

    // MARK: - Data Loading
    private func loadAllData() async {
        // Reset state
        characters = []
        relatedMangas = []
        relatedMangaDetails = [:]
        recommendations = []
        translatedSynopsis = nil
        translatedBackground = nil
        showOriginal = false

        // Load in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadCharacters() }
            group.addTask { await loadRelatedMangas() }
            group.addTask { await translateContent() }
        }
    }

    private func loadCharacters() async {
        isLoadingCharacters = true
        do {
            characters = try await repository.getMangaCharacters(mangaId: manga.id)
        } catch {
            print("Error cargando personajes: \(error)")
            characters = []
        }
        isLoadingCharacters = false
    }

    private func loadRelatedMangas() async {
        isLoadingRelated = true
        do {
            async let relations = repository.getMangaRelations(mangaId: manga.id)
            async let recs = repository.getMangaRecommendations(mangaId: manga.id)
            relatedMangas = try await relations
            recommendations = try await recs

            // Fetch detalles de mangas relacionados en paralelo para obtener imágenes
            await fetchRelatedMangaDetails()
        } catch {
            print("Error cargando mangas relacionados: \(error)")
            relatedMangas = []
            recommendations = []
        }
        isLoadingRelated = false
    }

    private func fetchRelatedMangaDetails() async {
        // Recopilar todos los IDs de mangas relacionados
        let mangaIds = relatedMangas
            .flatMap { $0.entry }
            .filter { $0.type == "manga" }
            .map { $0.malId }

        // Fetch en paralelo con límite para no saturar la API
        await withTaskGroup(of: (Int, Manga?).self) { group in
            for id in mangaIds {
                group.addTask {
                    do {
                        let manga = try await self.repository.getManga(byId: id)
                        return (id, manga)
                    } catch {
                        print("Error fetching manga \(id): \(error)")
                        return (id, nil)
                    }
                }
            }

            for await (id, manga) in group {
                if let manga = manga {
                    relatedMangaDetails[id] = manga
                }
            }
        }
    }

    private func loadAndNavigateToManga(id: Int) async {
        isLoadingManga = true
        do {
            let manga = try await repository.getManga(byId: id)
            selectedRelatedManga = manga
        } catch {
            print("Error cargando manga relacionado: \(error)")
        }
        isLoadingManga = false
    }

    private func translateContent() async {
        guard translationService.isConfigured && translationService.needsTranslation else { return }

        isTranslating = true
        let targetLanguage = translationService.currentLanguageCode

        do {
            if let synopsis = manga.sypnosis {
                translatedSynopsis = try await translationService.translate(synopsis, to: targetLanguage)
            }
            if let background = manga.background {
                translatedBackground = try await translationService.translate(background, to: targetLanguage)
            }
        } catch {
            print("Error traduciendo contenido: \(error)")
        }

        isTranslating = false
    }
}

#Preview(traits: .sampleData) {
    @Previewable @Namespace var namespace
    NavigationStack {
        MangaDetailView(manga: .test, namespace: namespace)
    }
}
