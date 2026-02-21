//
//  AcademyModels.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import Foundation

// MARK: - Author
struct Author: Codable, Identifiable, Hashable {
    let id: String
    let firstName: String
    let lastName: String
    let role: String
}

// MARK: - Theme
struct Theme: Codable, Identifiable, Hashable {
    let id: String
    let theme: String
}

// MARK: - Demographic
struct Demographic: Codable, Identifiable, Hashable {
    let id: String
    let demographic: String
}

// MARK: - Genre
struct Genre: Codable, Identifiable, Hashable {
    let id: String
    let genre: String
}

// MARK: - Manga
struct Manga: Codable, Identifiable, Hashable {
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
struct PaginatedResponse<T: Codable>: Codable {
    let items: [T]
    let metadata: Metadata
}

// MARK: - Metadata
struct Metadata: Codable {
    let total: Int
    let page: Int
    let per: Int
}

// MARK: - Users (for registration and login)
struct Users: Codable {
    var email: String
    var password: String
}

// MARK: - Token Response
struct TokenResponse: Codable {
    let token: String
}

// MARK: - User Manga Collection Request
struct UserMangaCollectionRequest: Codable {
    var manga: Int
    var completeCollection: Bool
    var volumesOwned: [Int]
    var readingVolume: Int?
}

// MARK: - User Manga Collection Response
struct UserMangaCollection: Codable, Identifiable, Hashable {
    let id: String
    let manga: Manga
    let completeCollection: Bool
    let volumesOwned: [Int]
    let readingVolume: Int?
}

// MARK: - Custom Search
struct CustomSearch: Codable {
    var searchTitle: String?
    var searchAuthorFirstName: String?
    var searchAuthorLastName: String?
    var searchGenres: [String]?
    var searchThemes: [String]?
    var searchDemographics: [String]?
    var searchContains: Bool
}

// MARK: - Test Data Extensions
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
        sypnosis: "Bulma, a headstrong 16-year-old girl, is on a quest to find the mythical Dragon Balls—seven scattered magic orbs that grant the finder a single wish. She has but one desire in mind: a perfect boyfriend.",
        background: "Dragon Ball has become one of the most successful manga series of all time, with over 230 million copies sold worldwide with 157 million in Japan alone.",
        mainPicture: "https://cdn.myanimelist.net/images/manga/1/267793l.jpg",
        url: "https://myanimelist.net/manga/42/Dragon_Ball",
        authors: [.test],
        genres: [
            Genre(id: "72C8E862-334F-4F00-B8EC-E1E4125BB7CD", genre: "Action"),
            Genre(id: "BE70E289-D414-46A9-8F15-928EAFBC5A32", genre: "Adventure"),
            Genre(id: "F974BCB6-B002-44A6-A224-90D1E50595A2", genre: "Comedy"),
            Genre(id: "2DEDC015-82DA-4EF4-B983-F0F58C8F689E", genre: "Sci-Fi")
        ],
        themes: [
            Theme(id: "ADC7CBC8-36B9-4E52-924A-4272B7B2CB2C", theme: "Martial Arts"),
            Theme(id: "472FB2AE-13C0-4EEE-9A45-A7B75AC5DC29", theme: "Super Power")
        ],
        demographics: [.test]
    )
}

extension Metadata {
    static let test = Metadata(
        total: 64833,
        page: 1,
        per: 10
    )
}
