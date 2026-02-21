//
//  MangaModel.swift
//  MisMangas
//
//  Created by Juan Carlos on 1/2/26.
//

import Foundation
import SwiftData

/// Manga cacheado en SwiftData para acceso offline
@Model
final class MangaModel {
    #Index<MangaModel>([\.title])
    @Attribute(.unique) var id: Int
    var title: String
    var titleEnglish: String?
    var titleJapanese: String?
    var status: String
    var score: Double
    var volumes: Int?
    var chapters: Int?
    var startDate: String?
    var endDate: String?
    var sypnosis: String?
    var background: String?
    var mainPicture: String
    var url: String

    // Arrays simplificados (nombres para mostrar)
    var authorNames: [String]
    var genreNames: [String]
    var themeNames: [String]
    var demographicNames: [String]

    // Metadata
    var cachedAt: Date

    // Relación inversa
    @Relationship(deleteRule: .cascade, inverse: \UserCollection.manga)
    var collections: [UserCollection]?

    init(
        id: Int,
        title: String,
        titleEnglish: String? = nil,
        titleJapanese: String? = nil,
        status: String,
        score: Double,
        volumes: Int? = nil,
        chapters: Int? = nil,
        startDate: String? = nil,
        endDate: String? = nil,
        sypnosis: String? = nil,
        background: String? = nil,
        mainPicture: String,
        url: String,
        authorNames: [String] = [],
        genreNames: [String] = [],
        themeNames: [String] = [],
        demographicNames: [String] = [],
        cachedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.titleEnglish = titleEnglish
        self.titleJapanese = titleJapanese
        self.status = status
        self.score = score
        self.volumes = volumes
        self.chapters = chapters
        self.startDate = startDate
        self.endDate = endDate
        self.sypnosis = sypnosis
        self.background = background
        self.mainPicture = mainPicture
        self.url = url
        self.authorNames = authorNames
        self.genreNames = genreNames
        self.themeNames = themeNames
        self.demographicNames = demographicNames
        self.cachedAt = cachedAt
    }

    /// Crea MangaModel desde un Manga de la API
    convenience init(from manga: Manga) {
        self.init(
            id: manga.id,
            title: manga.title,
            titleEnglish: manga.titleEnglish,
            titleJapanese: manga.titleJapanese,
            status: manga.status,
            score: manga.score,
            volumes: manga.volumes,
            chapters: manga.chapters,
            startDate: manga.startDate,
            endDate: manga.endDate,
            sypnosis: manga.sypnosis,
            background: manga.background,
            mainPicture: manga.mainPicture,
            url: manga.url,
            authorNames: manga.authors.map { "\($0.firstName) \($0.lastName)".trimmingCharacters(in: .whitespaces) },
            genreNames: manga.genres.map(\.genre),
            themeNames: manga.themes.map(\.theme),
            demographicNames: manga.demographics.map(\.demographic)
        )
    }

    /// Convierte a Manga para usar en vistas existentes
    func toManga() -> Manga {
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
            authors: authorNames.map { Author(id: UUID().uuidString, firstName: $0, lastName: "", role: "") },
            genres: genreNames.map { Genre(id: UUID().uuidString, genre: $0) },
            themes: themeNames.map { Theme(id: UUID().uuidString, theme: $0) },
            demographics: demographicNames.map { Demographic(id: UUID().uuidString, demographic: $0) }
        )
    }
}
