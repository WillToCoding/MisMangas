//
//  JikanURL.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import Foundation

/// URL base de Jikan API (MyAnimeList)
let jikanAPI = URL(string: "https://api.jikan.moe/v4")!

extension URL {
    // MARK: - Jikan API Endpoints

    /// Devuelve la URL para obtener personajes de un manga (Jikan API)
    static func mangaCharacters(mangaId: Int) -> URL {
        jikanAPI.appending(path: "manga/\(mangaId)/characters")
    }

    /// Devuelve la URL para obtener mangas relacionados (Jikan API)
    static func mangaRelations(mangaId: Int) -> URL {
        jikanAPI.appending(path: "manga/\(mangaId)/relations")
    }

    /// Devuelve la URL para obtener recomendaciones de manga (Jikan API)
    static func mangaRecommendations(mangaId: Int) -> URL {
        jikanAPI.appending(path: "manga/\(mangaId)/recommendations")
    }

    /// Devuelve la URL para búsqueda avanzada de manga (Jikan API)
    static func jikanMangaSearch(
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
    ) -> URL {
        var components = URLComponents(url: jikanAPI.appending(path: "manga"), resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = []

        if let query = query, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }
        if let genres = genres, !genres.isEmpty {
            queryItems.append(URLQueryItem(name: "genres", value: genres.map(String.init).joined(separator: ",")))
        }
        if let minScore = minScore {
            queryItems.append(URLQueryItem(name: "min_score", value: String(minScore)))
        }
        if let maxScore = maxScore {
            queryItems.append(URLQueryItem(name: "max_score", value: String(maxScore)))
        }
        if let startYear = startYear {
            queryItems.append(URLQueryItem(name: "start_date", value: "\(startYear)-01-01"))
        }
        if let endYear = endYear {
            queryItems.append(URLQueryItem(name: "end_date", value: "\(endYear)-12-31"))
        }
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        if let orderBy = orderBy {
            queryItems.append(URLQueryItem(name: "order_by", value: orderBy))
        }
        if let sort = sort {
            queryItems.append(URLQueryItem(name: "sort", value: sort))
        }
        queryItems.append(URLQueryItem(name: "page", value: String(page)))
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))

        components.queryItems = queryItems
        return components.url!
    }
}
