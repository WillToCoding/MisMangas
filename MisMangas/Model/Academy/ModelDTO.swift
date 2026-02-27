//
//  ModelDTO.swift
//  MisMangas
//
//  Created by Claude on 23/02/26.
//

import Foundation

// MARK: - DTOs
//
// Los DTOs (Data Transfer Objects) representan la estructura JSON
// que devuelve la Academy API. Cada DTO tiene una extension con
// una propiedad computed `toXxx` que lo convierte al modelo de dominio.
//
// Flujo: JSON → DTO (Codable) → Modelo de dominio
//

// MARK: - Author DTO

/// DTO para autores de manga desde la API.
struct AuthorDTO: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let role: String
}

// MARK: - Theme DTO

/// DTO para tematicas de manga desde la API.
struct ThemeDTO: Codable {
    let id: String
    let theme: String
}

// MARK: - Demographic DTO

/// DTO para demografias de manga desde la API.
struct DemographicDTO: Codable {
    let id: String
    let demographic: String
}

// MARK: - Genre DTO

/// DTO para generos de manga desde la API.
struct GenreDTO: Codable {
    let id: String
    let genre: String
}

// MARK: - Manga DTO

/// DTO de manga recibido de la Academy API.
///
/// Contiene todos los campos que devuelve el endpoint `/list/mangas`.
/// Usa la propiedad ``toManga`` para convertir al modelo de dominio.
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

/// DTO generico para respuestas paginadas de la API.
///
/// Envuelve cualquier tipo de items con metadata de paginacion.
struct PaginatedResponseDTO<T: Codable>: Codable {
    let items: [T]
    let metadata: MetadataDTO
}

// MARK: - Metadata DTO

/// DTO con informacion de paginacion.
struct MetadataDTO: Codable {
    let total: Int
    let page: Int
    let per: Int
}

// MARK: - User Manga Collection Response DTO

/// DTO para entrada de coleccion del usuario desde la API.
///
/// Representa un manga en la coleccion cloud del usuario con
/// sus volumenes poseidos y progreso de lectura.
struct UserMangaCollectionDTO: Codable {
    let id: String
    let manga: MangaDTO
    let completeCollection: Bool
    let volumesOwned: [Int]
    let readingVolume: Int?
}

// MARK: - DTO to Domain Conversions
//
// Cada DTO tiene una propiedad computed `toXxx` que convierte
// el DTO al modelo de dominio correspondiente.
//

extension AuthorDTO {
    /// Convierte el DTO a modelo de dominio ``Author``.
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
    /// Convierte el DTO a modelo de dominio ``Theme``.
    var toTheme: Theme {
        Theme(id: id, theme: theme)
    }
}

extension DemographicDTO {
    /// Convierte el DTO a modelo de dominio ``Demographic``.
    var toDemographic: Demographic {
        Demographic(id: id, demographic: demographic)
    }
}

extension GenreDTO {
    /// Convierte el DTO a modelo de dominio ``Genre``.
    var toGenre: Genre {
        Genre(id: id, genre: genre)
    }
}

extension MangaDTO {
    /// Convierte el DTO a modelo de dominio ``Manga``.
    ///
    /// Transforma tambien los DTOs anidados (autores, generos, etc.).
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
    /// Convierte el DTO a modelo de dominio ``Metadata``.
    var toMetadata: Metadata {
        Metadata(total: total, page: page, per: per)
    }
}

extension PaginatedResponseDTO where T == MangaDTO {
    /// Convierte la respuesta paginada de DTOs a respuesta de modelos de dominio.
    var toPaginatedResponse: PaginatedResponse<Manga> {
        PaginatedResponse(
            items: items.map(\.toManga),
            metadata: metadata.toMetadata
        )
    }
}

extension UserMangaCollectionDTO {
    /// Convierte el DTO a modelo de dominio ``UserMangaCollection``.
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
