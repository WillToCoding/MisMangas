//
//  JikanRepository.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import Foundation
import NetworkAPI

// MARK: - Jikan Repository
/// Repositorio para interactuar con la API de Jikan (MyAnimeList)
#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
struct JikanRepository: NetworkInteractor {

    // MARK: - Characters

    /// Obtiene los personajes de un manga desde Jikan API
    func getMangaCharacters(mangaId: Int) async throws -> [JikanCharacterData] {
        let response = try await getJSON(
            .get(url: .mangaCharacters(mangaId: mangaId)),
            type: JikanCharactersResponse.self
        )
        return response.data
    }

    // MARK: - Relations

    /// Obtiene mangas relacionados desde Jikan API
    func getMangaRelations(mangaId: Int) async throws -> [JikanRelation] {
        let response = try await getJSON(
            .get(url: .mangaRelations(mangaId: mangaId)),
            type: JikanRelationsResponse.self
        )
        return response.data
    }

    // MARK: - Recommendations

    /// Obtiene recomendaciones de manga desde Jikan API
    func getMangaRecommendations(mangaId: Int) async throws -> [JikanRecommendation] {
        let response = try await getJSON(
            .get(url: .mangaRecommendations(mangaId: mangaId)),
            type: JikanRecommendationsResponse.self
        )
        return response.data
    }

    // MARK: - Advanced Search

    /// Búsqueda avanzada de mangas usando Jikan API
    func searchMangas(
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
        let url = URL.jikanMangaSearch(
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
        return try await getJSON(.get(url: url), type: JikanMangaSearchResponse.self)
    }
}
#endif
