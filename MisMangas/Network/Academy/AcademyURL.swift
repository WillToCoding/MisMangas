//
//  AcademyURL.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import Foundation

/// URL base de la API Academy
let academyAPI = URL(string: "https://mymanga-acacademy-5607149ebe3d.herokuapp.com")!

extension URL {
    // MARK: - Academy List Endpoints
    static let listMangas = academyAPI.appending(path: "list/mangas")
    static let bestMangas = academyAPI.appending(path: "list/bestMangas")
    static let authors = academyAPI.appending(path: "list/authors")
    static let demographics = academyAPI.appending(path: "list/demographics")
    static let genres = academyAPI.appending(path: "list/genres")
    static let themes = academyAPI.appending(path: "list/themes")

    // MARK: - Academy Search Endpoints
    static let searchManga = academyAPI.appending(path: "search/manga")

    // MARK: - Academy User Endpoints
    static let users = academyAPI.appending(path: "users")
    static let usersLogin = academyAPI.appending(path: "users/login")
    static let usersRenew = academyAPI.appending(path: "users/renew")

    // MARK: - Academy Collection Endpoints
    static let collectionManga = academyAPI.appending(path: "collection/manga")

    // MARK: - Academy Dynamic Endpoints

    /// Devuelve la URL para obtener mangas por género
    static func mangaByGenre(_ genre: String) -> URL {
        academyAPI.appending(path: "list/mangaByGenre/\(genre.lowercased())")
    }

    /// Devuelve la URL para obtener mangas por demografía
    static func mangaByDemographic(_ demographic: String) -> URL {
        academyAPI.appending(path: "list/mangaByDemographic/\(demographic.lowercased())")
    }

    /// Devuelve la URL para obtener mangas por temática
    static func mangaByTheme(_ theme: String) -> URL {
        academyAPI.appending(path: "list/mangaByTheme/\(theme.lowercased())")
    }

    /// Devuelve la URL para obtener mangas por autor
    static func mangaByAuthor(_ authorId: String) -> URL {
        academyAPI.appending(path: "list/mangaByAuthor/\(authorId)")
    }

    /// Devuelve la URL para buscar mangas que empiezan por un texto
    static func mangasBeginsWith(_ text: String) -> URL {
        academyAPI.appending(path: "search/mangasBeginsWith/\(text)")
    }

    /// Devuelve la URL para buscar mangas que contienen un texto
    static func mangasContains(_ text: String) -> URL {
        academyAPI.appending(path: "search/mangasContains/\(text)")
    }

    /// Devuelve la URL para buscar autores
    static func searchAuthor(_ name: String) -> URL {
        academyAPI.appending(path: "search/author/\(name)")
    }

    /// Devuelve la URL para obtener un manga específico por ID
    static func manga(byId id: Int) -> URL {
        academyAPI.appending(path: "search/manga/\(id)")
    }

    /// Devuelve la URL para gestionar un manga específico en la colección
    static func collectionManga(byId mangaId: Int) -> URL {
        academyAPI.appending(path: "collection/manga/\(mangaId)")
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
