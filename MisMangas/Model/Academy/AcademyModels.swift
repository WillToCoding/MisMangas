//
//  AcademyModels.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import Foundation

// MARK: - Author

/// Autor de un manga (modelo de dominio).
struct Author: Identifiable, Hashable {
    let id: String
    let firstName: String
    let lastName: String
    let role: String
}

// MARK: - Theme

/// Tema temático de un manga (modelo de dominio).
struct Theme: Identifiable, Hashable {
    let id: String
    let theme: String
}

// MARK: - Demographic

/// Demografía objetivo de un manga (modelo de dominio).
struct Demographic: Identifiable, Hashable {
    let id: String
    let demographic: String
}

// MARK: - Genre

/// Género de un manga (modelo de dominio).
struct Genre: Identifiable, Hashable {
    let id: String
    let genre: String
}

// MARK: - Manga

/// Modelo de dominio de un manga.
///
/// Usado en la capa de presentación y lógica de negocio.
/// Los datos vienen convertidos desde `MangaDTO`.
struct Manga: Identifiable, Hashable {
    let id: Int
    let title: String
    let titleEnglish: String?
    let titleJapanese: String?
    let status: String
    let score: Double
    let volumes: Int?
    let chapters: Int?
    let startDate: String?
    let endDate: String?
    let sypnosis: String?
    let background: String?
    let mainPicture: String
    let url: String
    let authors: [Author]
    let genres: [Genre]
    let themes: [Theme]
    let demographics: [Demographic]
}

// MARK: - Paginated Response

/// Respuesta paginada genérica.
struct PaginatedResponse<T> {
    let items: [T]
    let metadata: Metadata
}

// MARK: - Metadata

/// Metadatos de paginación.
struct Metadata {
    let total: Int
    let page: Int
    let per: Int
}

// MARK: - Users (Request)

/// DTO para registro y login de usuarios.
struct Users: Codable {
    var email: String
    var password: String
}

// MARK: - Token Response

/// Respuesta de autenticación con JWT.
struct TokenResponse: Codable {
    let token: String
}

// MARK: - User Manga Collection Request

/// Request para añadir/actualizar un manga en la colección del usuario.
struct UserMangaCollectionRequest: Codable {
    var manga: Int
    var completeCollection: Bool
    var volumesOwned: [Int]
    var readingVolume: Int?
}

// MARK: - User Manga Collection

/// Manga en la colección del usuario (modelo de dominio).
struct UserMangaCollection: Identifiable, Hashable {
    let id: String
    let manga: Manga
    let completeCollection: Bool
    let volumesOwned: [Int]
    let readingVolume: Int?
}

// MARK: - Custom Search (Request)

/// Parámetros de búsqueda avanzada.
struct CustomSearch: Codable {
    var searchTitle: String?
    var searchAuthorFirstName: String?
    var searchAuthorLastName: String?
    var searchGenres: [String]?
    var searchThemes: [String]?
    var searchDemographics: [String]?
    var searchContains: Bool
}

// MARK: - Manga Computed Properties

extension Manga {
    /// URL limpia de la portada.
    var coverURL: URL? {
        URL(string: mainPicture.replacingOccurrences(of: "\"", with: ""))
    }
}

extension UserMangaCollection {
    /// URL limpia de la portada del manga.
    var coverURL: URL? {
        manga.coverURL
    }
}

// MARK: - Test Data

extension Author {
    static let test = Author(
        id: "998C1B16-E3DB-47D1-8157-8389B5345D03",
        firstName: "Akira",
        lastName: "Toriyama",
        role: "Story & Art"
    )
}

extension Theme {
    static let test = Theme(
        id: "ADC7CBC8-36B9-4E52-924A-4272B7B2CB2C",
        theme: "Martial Arts"
    )
}

extension Demographic {
    static let test = Demographic(
        id: "5E05BBF1-A72E-4231-9487-71CFE508F9F9",
        demographic: "Shounen"
    )
}

extension Genre {
    static let test = Genre(
        id: "72C8E862-334F-4F00-B8EC-E1E4125BB7CD",
        genre: "Action"
    )
}

extension Manga {
    static let test = Manga(
        id: 42,
        title: "Dragon Ball",
        titleEnglish: "Dragon Ball",
        titleJapanese: "ドラゴンボール",
        status: "finished",
        score: 8.41,
        volumes: 42,
        chapters: 520,
        startDate: "1984-11-20T00:00:00Z",
        endDate: "1995-05-23T00:00:00Z",
        sypnosis: "Bulma, a headstrong 16-year-old girl, is on a quest to find the mythical Dragon Balls—seven scattered magic orbs that grant the finder a single wish.",
        background: "Dragon Ball has become one of the most successful manga series of all time.",
        mainPicture: "https://cdn.myanimelist.net/images/manga/1/267793l.jpg",
        url: "https://myanimelist.net/manga/42/Dragon_Ball",
        authors: [.test],
        genres: [
            Genre(id: "72C8E862-334F-4F00-B8EC-E1E4125BB7CD", genre: "Action"),
            Genre(id: "BE70E289-D414-46A9-8F15-928EAFBC5A32", genre: "Adventure")
        ],
        themes: [.test],
        demographics: [.test]
    )

    /// Array de mangas de prueba con IDs únicos para previews de grids/listas
    static let testArray: [Manga] = [
        makeTestManga(index: 1),
        makeTestManga(index: 2),
        makeTestManga(index: 3),
        makeTestManga(index: 4),
        makeTestManga(index: 5),
        makeTestManga(index: 6)
    ]

    private static func makeTestManga(index: Int) -> Manga {
        Manga(
            id: 40 + index,
            title: "Test Manga \(index)",
            titleEnglish: "Test Manga \(index)",
            titleJapanese: "テストマンガ\(index)",
            status: index % 2 == 0 ? "finished" : "publishing",
            score: 7.0 + Double(index) * 0.2,
            volumes: index * 10,
            chapters: index * 50,
            startDate: "2020-01-0\(index)T00:00:00Z",
            endDate: index % 2 == 0 ? "2023-01-01T00:00:00Z" : nil,
            sypnosis: "Synopsis for test manga \(index).",
            background: nil,
            mainPicture: "https://cdn.myanimelist.net/images/manga/1/267793l.jpg",
            url: "https://myanimelist.net/manga/\(40 + index)",
            authors: [.test],
            genres: [.test],
            themes: [.test],
            demographics: [.test]
        )
    }
}

extension Metadata {
    static let test = Metadata(total: 64833, page: 1, per: 10)
}

extension UserMangaCollection {
    static let test = UserMangaCollection(
        id: "test-collection-1",
        manga: .test,
        completeCollection: false,
        volumesOwned: [1, 2, 3, 4, 5],
        readingVolume: 3
    )

    static let testComplete = UserMangaCollection(
        id: "test-collection-2",
        manga: .test,
        completeCollection: true,
        volumesOwned: Array(1...42),
        readingVolume: 42
    )
}
