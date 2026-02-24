//
//  MangaDetailViewModel.swift
//  MisMangas
//
//  Created by Juan Carlos on 22/02/26.
//

import Foundation

#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)

/// ViewModel para la vista de detalle de un manga.
///
/// `MangaDetailViewModel` maneja la carga de datos adicionales para la vista de detalle:
/// personajes, mangas relacionados, recomendaciones y traducciones.
///
/// ## Ejemplo de uso
///
/// ```swift
/// let viewModel = MangaDetailViewModel(manga: selectedManga)
/// await viewModel.loadAllData()
/// ```
@MainActor
@Observable
final class MangaDetailViewModel {
    // MARK: - Properties

    /// El manga actual que se está visualizando.
    let manga: Manga

    /// Lista de personajes del manga.
    var characters: [JikanCharacterData] = []

    /// Estado de carga de personajes.
    var charactersState: ViewState = .idle

    /// Relaciones con otros mangas (secuelas, precuelas, etc.).
    var relatedMangas: [JikanRelation] = []

    /// Cache de detalles de mangas relacionados por ID.
    var relatedMangaDetails: [Int: Manga] = [:]

    /// Lista de recomendaciones basadas en el manga actual.
    var recommendations: [JikanRecommendation] = []

    /// Estado de carga de mangas relacionados.
    var relatedState: ViewState = .idle

    /// Manga relacionado seleccionado para navegación.
    var selectedRelatedManga: Manga?

    /// Estado de carga para navegación a manga.
    var navigationState: ViewState = .idle

    /// Sinopsis traducida al idioma del dispositivo.
    var translatedSynopsis: String?

    /// Background traducido al idioma del dispositivo.
    var translatedBackground: String?

    /// Estado de traducción.
    var translationState: ViewState = .idle

    /// Controla si se muestra el texto original o traducido.
    var showOriginal = false

    // MARK: - Computed Properties (Compatibilidad)

    /// Indica si se están cargando los personajes.
    var isLoadingCharacters: Bool { charactersState.isLoading }

    /// Indica si se están cargando los mangas relacionados.
    var isLoadingRelated: Bool { relatedState.isLoading }

    /// Indica si se está cargando un manga para navegación.
    var isLoadingManga: Bool { navigationState.isLoading }

    /// Indica si se está traduciendo el contenido.
    var isTranslating: Bool { translationState.isLoading }

    // MARK: - Services

    private let repository: NetworkRepository
    private var translationService: TranslationService?

    // MARK: - Computed Properties

    /// Indica si la traducción está disponible y es necesaria.
    var canTranslate: Bool {
        guard let service = translationService else { return false }
        return service.isConfigured && service.needsTranslation
    }

    // MARK: - Initialization

    /// Crea una nueva instancia del ViewModel.
    ///
    /// - Parameters:
    ///   - manga: El manga a mostrar en detalle.
    ///   - repository: Repositorio de red a utilizar. Por defecto usa ``Network``.
    ///   - translationService: Servicio de traducción. Opcional, se puede configurar después.
    init(
        manga: Manga,
        repository: NetworkRepository = Network(),
        translationService: TranslationService? = nil
    ) {
        self.manga = manga
        self.repository = repository
        self.translationService = translationService
    }

    /// Configura el servicio de traducción.
    ///
    /// Usar cuando el servicio no está disponible en el momento de inicialización.
    func configure(translationService: TranslationService) {
        self.translationService = translationService
    }

    // MARK: - Public Methods

    /// Carga todos los datos adicionales del manga.
    ///
    /// Ejecuta en paralelo la carga de personajes, mangas relacionados y traducciones.
    func loadAllData() async {
        resetState()

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadCharacters() }
            group.addTask { await self.loadRelatedMangas() }
            group.addTask { await self.translateContent() }
        }
    }

    /// Navega a un manga relacionado por su ID.
    ///
    /// Carga el manga desde la API y lo asigna a `selectedRelatedManga` para navegación.
    ///
    /// - Parameter id: ID del manga a cargar.
    func loadAndNavigateToManga(id: Int) async {
        navigationState = .loading
        do {
            let manga = try await repository.getManga(byId: id)
            selectedRelatedManga = manga
            navigationState = .loaded
        } catch {
            navigationState = .error(error.localizedDescription)
        }
    }

    /// Alterna entre mostrar el texto original o traducido.
    func toggleTranslation() {
        showOriginal.toggle()
    }

    // MARK: - Private Methods

    private func resetState() {
        characters = []
        relatedMangas = []
        relatedMangaDetails = [:]
        recommendations = []
        translatedSynopsis = nil
        translatedBackground = nil
        showOriginal = false
        charactersState = .idle
        relatedState = .idle
        translationState = .idle
        navigationState = .idle
    }

    private func loadCharacters() async {
        charactersState = .loading
        do {
            characters = try await repository.getMangaCharacters(mangaId: manga.id)
            charactersState = characters.isEmpty ? .empty : .loaded
        } catch {
            charactersState = .error(error.localizedDescription)
            characters = []
        }
    }

    private func loadRelatedMangas() async {
        relatedState = .loading
        do {
            async let relations = repository.getMangaRelations(mangaId: manga.id)
            async let recs = repository.getMangaRecommendations(mangaId: manga.id)
            relatedMangas = try await relations
            recommendations = try await recs

            await fetchRelatedMangaDetails()
            relatedState = (relatedMangas.isEmpty && recommendations.isEmpty) ? .empty : .loaded
        } catch {
            relatedState = .error(error.localizedDescription)
            relatedMangas = []
            recommendations = []
        }
    }

    private func fetchRelatedMangaDetails() async {
        let mangaIds = relatedMangas
            .flatMap { $0.entry }
            .filter { $0.type == "manga" }
            .map { $0.malId }

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

    private func translateContent() async {
        guard canTranslate, let service = translationService else { return }

        translationState = .loading
        let targetLanguage = service.currentLanguageCode

        do {
            if let synopsis = manga.sypnosis {
                translatedSynopsis = try await service.translate(synopsis, to: targetLanguage)
            }
            if let background = manga.background {
                translatedBackground = try await service.translate(background, to: targetLanguage)
            }
            translationState = .loaded
        } catch {
            translationState = .error(error.localizedDescription)
        }
    }
}

#endif
