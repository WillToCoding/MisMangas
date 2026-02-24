//
//  ModelDTO.swift
//  MisMangas
//
//  Created by Claude on 23/02/26.
//

import Foundation

// MARK: - Author DTO

struct AuthorDTO: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let role: String
}

// MARK: - Theme DTO

struct ThemeDTO: Codable {
    let id: String
    let theme: String
}

// MARK: - Demographic DTO

struct DemographicDTO: Codable {
    let id: String
    let demographic: String
}

// MARK: - Genre DTO

struct GenreDTO: Codable {
    let id: String
    let genre: String
}

// MARK: - Manga DTO

/// DTO de manga recibido de la Academy API.
struct MangaDTO: Codable {
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
    let authors: [AuthorDTO]
    let genres: [GenreDTO]
    let themes: [ThemeDTO]
    let demographics: [DemographicDTO]
}

// MARK: - Paginated Response DTO

struct PaginatedResponseDTO<T: Codable>: Codable {
    let items: [T]
    let metadata: MetadataDTO
}

// MARK: - Metadata DTO

struct MetadataDTO: Codable {
    let total: Int
    let page: Int
    let per: Int
}

// MARK: - User Manga Collection Response DTO

struct UserMangaCollectionDTO: Codable {
    let id: String
    let manga: MangaDTO
    let completeCollection: Bool
    let volumesOwned: [Int]
    let readingVolume: Int?
}

// MARK: - DTO to Domain Conversions

extension AuthorDTO {
    var toAuthor: Author {
        Author(
            id: id,
            firstName: firstName,
            lastName: lastName,
            role: role
        )
    }
}

extension ThemeDTO {
    var toTheme: Theme {
        Theme(id: id, theme: theme)
    }
}

extension DemographicDTO {
    var toDemographic: Demographic {
        Demographic(id: id, demographic: demographic)
    }
}

extension GenreDTO {
    var toGenre: Genre {
        Genre(id: id, genre: genre)
    }
}

extension MangaDTO {
    var toManga: Manga {
        Manga(
            id: id,
            title: title,
            titleEnglish: titleEnglish,
            titleJapanese: titleJapanese,
            status: status,
            score: score,
            volumes: volumes,
            chapters: chapters,
            startDate: startDate,
            endDate: endDate,
            sypnosis: sypnosis,
            background: background,
            mainPicture: mainPicture,
            url: url,
            authors: authors.map(\.toAuthor),
            genres: genres.map(\.toGenre),
            themes: themes.map(\.toTheme),
            demographics: demographics.map(\.toDemographic)
        )
    }
}

extension MetadataDTO {
    var toMetadata: Metadata {
        Metadata(total: total, page: page, per: per)
    }
}

extension PaginatedResponseDTO where T == MangaDTO {
    var toPaginatedResponse: PaginatedResponse<Manga> {
        PaginatedResponse(
            items: items.map(\.toManga),
            metadata: metadata.toMetadata
        )
    }
}

extension UserMangaCollectionDTO {
    var toUserMangaCollection: UserMangaCollection {
        UserMangaCollection(
            id: id,
            manga: manga.toManga,
            completeCollection: completeCollection,
            volumesOwned: volumesOwned,
            readingVolume: readingVolume
        )
    }
}
