//
//  NetworkRepository.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import Foundation
import NetworkAPI

// MARK: - Protocol

/// Protocolo que define las operaciones de red disponibles en la app.
///
/// `NetworkRepository` abstrae la capa de red permitiendo:
/// - Inyeccion de dependencias para testing con mocks
/// - Intercambio de implementaciones sin afectar a los ViewModels
/// - Definicion clara del contrato de la API
///
/// ## Implementaciones
///
/// - ``Network``: Implementacion de produccion que usa Academy y Jikan APIs
///
/// ## Ejemplo de mock para testing
///
/// ```swift
/// struct MockNetworkRepository: NetworkRepository {
///     func getMangas(page: Int, per: Int) async throws -> PaginatedResponse<Manga> {
///         return PaginatedResponse(items: [.preview], metadata: .init(total: 1, page: 1, per: 1))
///     }
///     // ... implementar otros metodos
/// }
/// ```
protocol NetworkRepository: Sendable, NetworkInteractor {
    // List
    func getMangas(page: Int, per: Int) async throws -> PaginatedResponse<Manga>
    func getBestMangas(page: Int, per: Int) async throws -> PaginatedResponse<Manga>

    // Filter Options
    func getGenres() async throws -> [String]
    func getDemographics() async throws -> [String]
    func getThemes() async throws -> [String]

    // Filter by Category
    func getMangasByGenre(_ genre: String, page: Int, per: Int) async throws -> PaginatedResponse<Manga>
    func getMangasByDemographic(_ demographic: String, page: Int, per: Int) async throws -> PaginatedResponse<Manga>
    func getMangasByTheme(_ theme: String, page: Int, per: Int) async throws -> PaginatedResponse<Manga>

    // Search
    func searchMangasBeginsWith(_ text: String, page: Int, per: Int) async throws -> PaginatedResponse<Manga>
    func searchMangasContains(_ text: String, page: Int, per: Int) async throws -> PaginatedResponse<Manga>
    func searchCustom(_ search: CustomSearch, page: Int, per: Int) async throws -> PaginatedResponse<Manga>

    // Jikan Search (not available on watchOS)
    #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
    func searchMangasJikan(
        query: String?,
        genres: [Int]?,
        minScore: Double?,
        maxScore: Double?,
        startYear: Int?,
        endYear: Int?,
        status: String?,
        orderBy: String?,
        sort: String?,
        page: Int,
        limit: Int
    ) async throws -> JikanMangaSearchResponse
    #endif
}

// MARK: - Production Implementation

/// Fachada que unifica el acceso a las APIs de Academy y Jikan.
///
/// `Network` implementa ``NetworkRepository`` combinando dos fuentes de datos:
///
/// - **Academy API**: Datos principales de mangas, autenticacion y colecciones de usuario
/// - **Jikan API**: Datos adicionales como personajes, relaciones y filtros avanzados
///
/// Esta arquitectura permite:
/// - Enriquecer los datos de mangas con informacion de Jikan
/// - Usar filtros avanzados (anio, score) no disponibles en Academy
/// - Mantener una unica interfaz para los ViewModels
///
/// ## Ejemplo de uso
///
/// ```swift
/// let network = Network()
///
/// // Obtener mangas paginados
/// let response = try await network.getMangas(page: 1, per: 20)
///
/// // Buscar por texto
/// let results = try await network.searchMangasContains("dragon", page: 1, per: 10)
///
/// // Obtener personajes (Jikan)
/// let characters = try await network.getMangaCharacters(mangaId: 42)
/// ```
struct Network: NetworkRepository {

    private let academy = AcademyRepository()
    #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
    private let jikan = JikanRepository()
    #endif

    // MARK: - Academy: List Endpoints

    /// Obtiene mangas paginados desde Academy API.
    ///
    /// - Parameters:
    ///   - page: Numero de pagina (desde 1).
    ///   - per: Cantidad de elementos por pagina.
    /// - Returns: Respuesta paginada con mangas y metadatos.
    func getMangas(page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await academy.getMangas(page: page, per: per)
    }

    /// Obtiene los mejores mangas ordenados por puntuacion.
    func getBestMangas(page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await academy.getBestMangas(page: page, per: per)
    }

    /// Obtiene la lista completa de autores (no paginada).
    func getAuthors() async throws -> [Author] {
        try await academy.getAuthors()
    }

    /// Obtiene las demografias disponibles (ej: "Shounen", "Seinen").
    func getDemographics() async throws -> [String] {
        try await academy.getDemographics()
    }

    /// Obtiene los generos disponibles (ej: "Action", "Romance").
    func getGenres() async throws -> [String] {
        try await academy.getGenres()
    }

    /// Obtiene los temas disponibles (ej: "School", "Mecha").
    func getThemes() async throws -> [String] {
        try await academy.getThemes()
    }

    // MARK: - Academy: Filter by Category

    /// Obtiene mangas filtrados por un genero especifico.
    func getMangasByGenre(_ genre: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await academy.getMangasByGenre(genre, page: page, per: per)
    }

    /// Obtiene mangas filtrados por una demografia especifica.
    func getMangasByDemographic(_ demographic: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await academy.getMangasByDemographic(demographic, page: page, per: per)
    }

    /// Obtiene mangas filtrados por un tema especifico.
    func getMangasByTheme(_ theme: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await academy.getMangasByTheme(theme, page: page, per: per)
    }

    /// Obtiene mangas de un autor especifico por su ID.
    func getMangasByAuthor(_ authorId: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await academy.getMangasByAuthor(authorId, page: page, per: per)
    }

    // MARK: - Academy: Search

    /// Busca mangas cuyo titulo comienza con el texto dado.
    func searchMangasBeginsWith(_ text: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await academy.searchMangasBeginsWith(text, page: page, per: per)
    }

    /// Busca mangas cuyo titulo contiene el texto dado.
    func searchMangasContains(_ text: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await academy.searchMangasContains(text, page: page, per: per)
    }

    /// Busca autores por nombre (primer o ultimo nombre).
    func searchAuthor(_ name: String) async throws -> [Author] {
        try await academy.searchAuthor(name)
    }

    /// Obtiene un manga especifico por su ID.
    func getManga(byId id: Int) async throws -> Manga {
        try await academy.getManga(byId: id)
    }

    /// Realiza una busqueda personalizada con multiples criterios.
    ///
    /// Permite combinar titulo, autor, generos, temas y demografias en una sola busqueda.
    func searchCustom(_ search: CustomSearch, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await academy.searchCustom(search, page: page, per: per)
    }

    // MARK: - Academy: Authentication

    /// Registra un nuevo usuario en el sistema.
    ///
    /// - Parameter users: Credenciales del usuario (email y password).
    /// - Note: Requiere header `App-Token` para autorizar la solicitud.
    func registerUser(_ users: Users) async throws {
        try await academy.registerUser(users)
    }

    /// Inicia sesion y obtiene un token JWT.
    ///
    /// - Returns: Token JWT valido por 2 dias.
    func login(email: String, password: String) async throws -> String {
        try await academy.login(email: email, password: password)
    }

    /// Renueva un token JWT existente.
    ///
    /// - Returns: Nuevo token JWT. El token anterior queda invalidado.
    func renewToken(_ currentToken: String) async throws -> String {
        try await academy.renewToken(currentToken)
    }

    // MARK: - Academy: Cloud Collection

    /// Obtiene la coleccion completa de mangas del usuario.
    ///
    /// - Note: Esta respuesta no esta paginada.
    func getUserCollection(token: String) async throws -> [UserMangaCollection] {
        try await academy.getUserCollection(token: token)
    }

    /// Agrega o actualiza un manga en la coleccion del usuario.
    func addToCollection(_ request: UserMangaCollectionRequest, token: String) async throws {
        try await academy.addToCollection(request, token: token)
    }

    /// Elimina un manga de la coleccion del usuario.
    func deleteFromCollection(mangaId: Int, token: String) async throws {
        try await academy.deleteFromCollection(mangaId: mangaId, token: token)
    }

    // MARK: - Jikan: Characters, Relations, Recommendations

    #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
    /// Obtiene los personajes de un manga desde Jikan API.
    ///
    /// - Note: No disponible en watchOS por limitaciones de la plataforma.
    func getMangaCharacters(mangaId: Int) async throws -> [JikanCharacterData] {
        try await jikan.getMangaCharacters(mangaId: mangaId)
    }

    /// Obtiene las relaciones de un manga (secuelas, precuelas, spin-offs).
    func getMangaRelations(mangaId: Int) async throws -> [JikanRelation] {
        try await jikan.getMangaRelations(mangaId: mangaId)
    }

    /// Obtiene recomendaciones de mangas similares.
    func getMangaRecommendations(mangaId: Int) async throws -> [JikanRecommendation] {
        try await jikan.getMangaRecommendations(mangaId: mangaId)
    }

    /// Busca mangas en Jikan API con filtros avanzados.
    ///
    /// Jikan permite filtros no disponibles en Academy API como
    /// rango de anios y puntuacion minima/maxima.
    ///
    /// - Parameters:
    ///   - query: Texto de busqueda opcional.
    ///   - genres: IDs de generos de Jikan (diferentes a Academy).
    ///   - minScore: Puntuacion minima (0-10).
    ///   - maxScore: Puntuacion maxima (0-10).
    ///   - startYear: Anio de inicio de publicacion.
    ///   - endYear: Anio de fin de publicacion.
    ///   - status: Estado de publicacion ("publishing", "complete", "hiatus").
    ///   - orderBy: Campo de ordenamiento ("score", "title", "start_date").
    ///   - sort: Direccion del orden ("asc", "desc").
    ///   - page: Numero de pagina.
    ///   - limit: Elementos por pagina (max 25).
    func searchMangasJikan(
        query: String? = nil,
        genres: [Int]? = nil,
        minScore: Double? = nil,
        maxScore: Double? = nil,
        startYear: Int? = nil,
        endYear: Int? = nil,
        status: String? = nil,
        orderBy: String? = nil,
        sort: String? = nil,
        page: Int = 1,
        limit: Int = 25
    ) async throws -> JikanMangaSearchResponse {
        try await jikan.searchMangas(
            query: query,
            genres: genres,
            minScore: minScore,
            maxScore: maxScore,
            startYear: startYear,
            endYear: endYear,
            status: status,
            orderBy: orderBy,
            sort: sort,
            page: page,
            limit: limit
        )
    }
    #endif
}
