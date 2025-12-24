//
//  URL.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import Foundation

// URL base de la API
let api = URL(string: "https://mymanga-acacademy-5607149ebe3d.herokuapp.com")!

// URL base de Jikan API (MyAnimeList)
let jikanAPI = URL(string: "https://api.jikan.moe/v4")!

extension URL {
    // MARK: - List Endpoints
    static let listMangas = api.appending(path: "list/mangas")
    static let bestMangas = api.appending(path: "list/bestMangas")
    static let authors = api.appending(path: "list/authors")
    static let demographics = api.appending(path: "list/demographics")
    static let genres = api.appending(path: "list/genres")
    static let themes = api.appending(path: "list/themes")

    // MARK: - Search Endpoints
    static let searchManga = api.appending(path: "search/manga")

    // MARK: - User Endpoints
    static let users = api.appending(path: "users")
    static let usersLogin = api.appending(path: "users/login")
    static let usersRenew = api.appending(path: "users/renew")

    // MARK: - Collection Endpoints
    static let collectionManga = api.appending(path: "collection/manga")

    // MARK: - Static Functions for Dynamic Endpoints

    /// Devuelve la URL para obtener mangas por género
    static func mangaByGenre(_ genre: String) -> URL {
        api.appending(path: "list/mangaByGenre/\(genre.lowercased())")
    }

    /// Devuelve la URL para obtener mangas por demografía
    static func mangaByDemographic(_ demographic: String) -> URL {
        api.appending(path: "list/mangaByDemographic/\(demographic.lowercased())")
    }

    /// Devuelve la URL para obtener mangas por temática
    static func mangaByTheme(_ theme: String) -> URL {
        api.appending(path: "list/mangaByTheme/\(theme.lowercased())")
    }

    /// Devuelve la URL para obtener mangas por autor
    static func mangaByAuthor(_ authorId: String) -> URL {
        api.appending(path: "list/mangaByAuthor/\(authorId)")
    }

    /// Devuelve la URL para buscar mangas que empiezan por un texto
    static func mangasBeginsWith(_ text: String) -> URL {
        api.appending(path: "search/mangasBeginsWith/\(text)")
    }

    /// Devuelve la URL para buscar mangas que contienen un texto
    static func mangasContains(_ text: String) -> URL {
        api.appending(path: "search/mangasContains/\(text)")
    }

    /// Devuelve la URL para buscar autores
    static func searchAuthor(_ name: String) -> URL {
        api.appending(path: "search/author/\(name)")
    }

    /// Devuelve la URL para obtener un manga específico por ID
    static func manga(byId id: Int) -> URL {
        api.appending(path: "search/manga/\(id)")
    }

    /// Devuelve la URL para gestionar un manga específico en la colección
    static func collectionManga(byId mangaId: Int) -> URL {
        api.appending(path: "collection/manga/\(mangaId)")
    }

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

    // MARK: - URL with Query Parameters

    /// Añade parámetros de paginación a una URL
    func withPagination(page: Int = 1, per: Int = 10) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per", value: "\(per)")
        ]
        return components.url!
    }
}
