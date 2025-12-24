//
//  JikanCharacter.swift
//  MisMangas
//
//  Created by Juan Carlos on 23/12/25.
//

import Foundation

// MARK: - Jikan API Response
struct JikanCharactersResponse: Codable {
    let data: [JikanCharacterData]
}

struct JikanCharacterData: Codable, Identifiable {
    let character: JikanCharacter
    let role: String

    var id: Int { character.malId }
}

struct JikanCharacter: Codable {
    let malId: Int
    let name: String
    let images: JikanImages

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case name
        case images
    }
}

struct JikanImages: Codable {
    let jpg: JikanImageURL
}

struct JikanImageURL: Codable {
    let imageUrl: String

    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
    }
}

// MARK: - Jikan Relations Response

struct JikanRelationsResponse: Codable {
    let data: [JikanRelation]
}

struct JikanRelation: Codable, Identifiable {
    let relation: String
    let entry: [JikanRelationEntry]

    var id: String { relation }
}

struct JikanRelationEntry: Codable, Identifiable, Hashable {
    let malId: Int
    let type: String
    let name: String
    let url: String

    var id: Int { malId }

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case type
        case name
        case url
    }
}

// MARK: - Jikan Recommendations Response

struct JikanRecommendationsResponse: Codable {
    let data: [JikanRecommendation]
}

struct JikanRecommendation: Codable, Identifiable {
    let entry: JikanRecommendationEntry
    let votes: Int

    var id: Int { entry.malId }
}

struct JikanRecommendationEntry: Codable {
    let malId: Int
    let title: String
    let url: String
    let images: JikanMangaImages

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case title
        case url
        case images
    }
}

// MARK: - Jikan Manga Search Response

struct JikanMangaSearchResponse: Codable {
    let data: [JikanManga]
    let pagination: JikanPagination
}

struct JikanPagination: Codable {
    let lastVisiblePage: Int
    let hasNextPage: Bool
    let currentPage: Int

    enum CodingKeys: String, CodingKey {
        case lastVisiblePage = "last_visible_page"
        case hasNextPage = "has_next_page"
        case currentPage = "current_page"
    }
}

struct JikanManga: Codable, Identifiable, Hashable {
    let malId: Int
    let title: String
    let titleEnglish: String?
    let titleJapanese: String?
    let images: JikanMangaImages
    let score: Double?
    let scoredBy: Int?
    let status: String?
    let volumes: Int?
    let chapters: Int?
    let synopsis: String?
    let background: String?
    let published: JikanPublished?
    let genres: [JikanGenre]?
    let themes: [JikanGenre]?
    let demographics: [JikanGenre]?
    let authors: [JikanAuthor]?

    var id: Int { malId }

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case title
        case titleEnglish = "title_english"
        case titleJapanese = "title_japanese"
        case images
        case score
        case scoredBy = "scored_by"
        case status
        case volumes
        case chapters
        case synopsis
        case background
        case published
        case genres
        case themes
        case demographics
        case authors
    }

    // Convertir a Manga del modelo de la app
    func toManga() -> Manga {
        Manga(
            id: malId,
            title: title,
            titleEnglish: titleEnglish,
            titleJapanese: titleJapanese,
            status: status ?? "unknown",
            score: score ?? 0.0,
            volumes: volumes,
            chapters: chapters,
            startDate: published?.from,
            endDate: published?.to,
            sypnosis: synopsis,
            background: background,
            mainPicture: images.jpg.largeImageUrl ?? images.jpg.imageUrl,
            url: "https://myanimelist.net/manga/\(malId)",
            authors: authors?.map { Author(id: UUID().uuidString, firstName: $0.name.components(separatedBy: ", ").last ?? "", lastName: $0.name.components(separatedBy: ", ").first ?? "", role: $0.type) } ?? [],
            genres: genres?.map { Genre(id: UUID().uuidString, genre: $0.name) } ?? [],
            themes: themes?.map { Theme(id: UUID().uuidString, theme: $0.name) } ?? [],
            demographics: demographics?.map { Demographic(id: UUID().uuidString, demographic: $0.name) } ?? []
        )
    }
}

struct JikanMangaImages: Codable, Hashable {
    let jpg: JikanMangaImageURL
}

struct JikanMangaImageURL: Codable, Hashable {
    let imageUrl: String
    let smallImageUrl: String?
    let largeImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
        case smallImageUrl = "small_image_url"
        case largeImageUrl = "large_image_url"
    }
}

struct JikanPublished: Codable, Hashable {
    let from: String?
    let to: String?
}

struct JikanGenre: Codable, Hashable {
    let malId: Int
    let type: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case type
        case name
    }
}

struct JikanAuthor: Codable, Hashable {
    let malId: Int
    let type: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case type
        case name
    }
}
