//
//  NetworkTest.swift
//  MisMangas
//
//  Created by Juan Carlos on 2/2/26.
//

import Foundation

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
