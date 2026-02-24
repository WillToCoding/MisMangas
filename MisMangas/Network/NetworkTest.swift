//
//  NetworkTest.swift
//  MisMangas
//
//  Created by Juan Carlos on 2/2/26.
//

import Foundation
import NetworkAPI

// MARK: - Test Errors

/// Errores simulados para testing.
enum TestNetworkError: LocalizedError {
    case unauthorized       // 401
    case forbidden          // 403
    case notFound           // 404
    case serverError        // 500
    case timeout
    case noConnection
    case invalidJSON

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "HTTP status code: 401"
        case .forbidden: return "HTTP status code: 403"
        case .notFound: return "HTTP status code: 404"
        case .serverError: return "HTTP status code: 500"
        case .timeout: return "The request timed out"
        case .noConnection: return "No internet connection"
        case .invalidJSON: return "JSON error: Invalid format"
        }
    }
}

// MARK: - NetworkTest (Success)

/// Implementación de test que devuelve datos locales.
/// No hace llamadas a la red.
struct NetworkTest: NetworkRepository {

    // Datos de prueba
    var mangas: [Manga] {
        [.test]
    }

    var genres: [String] {
        ["Action", "Adventure", "Comedy", "Drama", "Fantasy"]
    }

    var demographics: [String] {
        ["Shounen", "Seinen", "Shoujo", "Josei"]
    }

    var themes: [String] {
        ["Martial Arts", "School", "Gore", "Military"]
    }

    // MARK: - List Endpoints

    func getMangas(page: Int, per: Int) async throws -> PaginatedResponse<Manga> {
        PaginatedResponse(items: mangas, metadata: .test)
    }

    func getBestMangas(page: Int, per: Int) async throws -> PaginatedResponse<Manga> {
        PaginatedResponse(items: mangas, metadata: .test)
    }

    // MARK: - Filter Options

    func getGenres() async throws -> [String] {
        genres
    }

    func getDemographics() async throws -> [String] {
        demographics
    }

    func getThemes() async throws -> [String] {
        themes
    }

    // MARK: - Filter by Category

    func getMangasByGenre(_ genre: String, page: Int, per: Int) async throws -> PaginatedResponse<Manga> {
        let filtered = mangas.filter { $0.genres.contains { $0.genre == genre } }
        return PaginatedResponse(items: filtered, metadata: .test)
    }

    func getMangasByDemographic(_ demographic: String, page: Int, per: Int) async throws -> PaginatedResponse<Manga> {
        let filtered = mangas.filter { $0.demographics.contains { $0.demographic == demographic } }
        return PaginatedResponse(items: filtered, metadata: .test)
    }

    func getMangasByTheme(_ theme: String, page: Int, per: Int) async throws -> PaginatedResponse<Manga> {
        let filtered = mangas.filter { $0.themes.contains { $0.theme == theme } }
        return PaginatedResponse(items: filtered, metadata: .test)
    }

    // MARK: - Search

    func searchMangasBeginsWith(_ text: String, page: Int, per: Int) async throws -> PaginatedResponse<Manga> {
        let filtered = mangas.filter { $0.title.lowercased().hasPrefix(text.lowercased()) }
        return PaginatedResponse(items: filtered, metadata: .test)
    }

    func searchMangasContains(_ text: String, page: Int, per: Int) async throws -> PaginatedResponse<Manga> {
        let filtered = mangas.filter { $0.title.lowercased().contains(text.lowercased()) }
        return PaginatedResponse(items: filtered, metadata: .test)
    }

    func searchCustom(_ search: CustomSearch, page: Int, per: Int) async throws -> PaginatedResponse<Manga> {
        PaginatedResponse(items: mangas, metadata: .test)
    }

    // MARK: - Detail

    func getManga(byId id: Int) async throws -> Manga {
        mangas.first { $0.id == id } ?? .test
    }

    // MARK: - Authentication

    func registerUser(_ users: Users) async throws {
    }

    func login(email: String, password: String) async throws -> String {
        "test-token-12345"
    }

    func renewToken(_ currentToken: String) async throws -> String {
        "renewed-test-token-12345"
    }

    // MARK: - Cloud Collection

    func getUserCollection(token: String) async throws -> [UserMangaCollection] {
        []
    }

    func addToCollection(_ request: UserMangaCollectionRequest, token: String) async throws {
    }

    func deleteFromCollection(mangaId: Int, token: String) async throws {
    }

    // MARK: - Jikan: Characters, Relations, Recommendations (not available on watchOS)

    #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
    func getMangaCharacters(mangaId: Int) async throws -> [JikanCharacterData] {
        []
    }

    func getMangaRelations(mangaId: Int) async throws -> [JikanRelation] {
        []
    }

    func getMangaRecommendations(mangaId: Int) async throws -> [JikanRecommendation] {
        []
    }
    #endif

    // MARK: - Jikan Search (not available on watchOS)

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
    ) async throws -> JikanMangaSearchResponse {
        JikanMangaSearchResponse(
            data: [],
            pagination: JikanPagination(lastVisiblePage: 1, hasNextPage: false, currentPage: 1)
        )
    }
    #endif
}

// MARK: - NetworkTestWithError (Failure simulation)

/// Implementación de test que simula errores de red.
///
/// Usar para probar el manejo de errores en ViewModels.
///
/// ```swift
/// let network = NetworkTestWithError(error: .unauthorized)
/// let vm = MangaViewModel(repository: network)
/// await vm.fetchMangas()
/// #expect(vm.state == .error("HTTP status code: 401"))
/// ```
struct NetworkTestWithError: NetworkRepository {

    let error: TestNetworkError

    init(error: TestNetworkError = .serverError) {
        self.error = error
    }

    // MARK: - All methods throw the configured error

    func getMangas(page: Int, per: Int) async throws -> PaginatedResponse<Manga> {
        throw error
    }

    func getBestMangas(page: Int, per: Int) async throws -> PaginatedResponse<Manga> {
        throw error
    }

    func getGenres() async throws -> [String] {
        throw error
    }

    func getDemographics() async throws -> [String] {
        throw error
    }

    func getThemes() async throws -> [String] {
        throw error
    }

    func getMangasByGenre(_ genre: String, page: Int, per: Int) async throws -> PaginatedResponse<Manga> {
        throw error
    }

    func getMangasByDemographic(_ demographic: String, page: Int, per: Int) async throws -> PaginatedResponse<Manga> {
        throw error
    }

    func getMangasByTheme(_ theme: String, page: Int, per: Int) async throws -> PaginatedResponse<Manga> {
        throw error
    }

    func searchMangasBeginsWith(_ text: String, page: Int, per: Int) async throws -> PaginatedResponse<Manga> {
        throw error
    }

    func searchMangasContains(_ text: String, page: Int, per: Int) async throws -> PaginatedResponse<Manga> {
        throw error
    }

    func searchCustom(_ search: CustomSearch, page: Int, per: Int) async throws -> PaginatedResponse<Manga> {
        throw error
    }

    func getManga(byId id: Int) async throws -> Manga {
        throw error
    }

    func registerUser(_ users: Users) async throws {
        throw error
    }

    func login(email: String, password: String) async throws -> String {
        throw error
    }

    func renewToken(_ currentToken: String) async throws -> String {
        throw error
    }

    func getUserCollection(token: String) async throws -> [UserMangaCollection] {
        throw error
    }

    func addToCollection(_ request: UserMangaCollectionRequest, token: String) async throws {
        throw error
    }

    func deleteFromCollection(mangaId: Int, token: String) async throws {
        throw error
    }

    #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
    func getMangaCharacters(mangaId: Int) async throws -> [JikanCharacterData] {
        throw error
    }

    func getMangaRelations(mangaId: Int) async throws -> [JikanRelation] {
        throw error
    }

    func getMangaRecommendations(mangaId: Int) async throws -> [JikanRecommendation] {
        throw error
    }

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
    ) async throws -> JikanMangaSearchResponse {
        throw error
    }
    #endif
}
