//
//  MangaModel.swift
//  MisMangas
//
//  Created by Juan Carlos on 1/2/26.
//

import Foundation
import SwiftData

/// Modelo SwiftData para persistencia local de mangas.
///
/// ## Overview
/// `MangaModel` cachea los datos de un manga de la API para acceso offline.
/// Los datos relacionados (autores, géneros, etc.) se almacenan como arrays
/// de strings desnormalizados para simplificar las consultas.
///
/// ## Topics
///
/// ### Creación
/// - ``init(from:)``
/// - ``toManga()``
///
/// ### Relaciones
/// - ``collections``
@Model
final class MangaModel {
    #Index<MangaModel>([\.title])

    /// Identificador único del manga (de la API).
    @Attribute(.unique) var id: Int

    /// Título principal del manga.
    var title: String

    /// Título en inglés, si existe.
    var titleEnglish: String?

    /// Título en japonés, si existe.
    var titleJapanese: String?

    /// Estado de publicación: `finished`, `publishing`, `on_hiatus`, etc.
    var status: String

    /// Puntuación media del manga (0-10).
    var score: Double

    /// Número total de volúmenes, `nil` si está en publicación.
    var volumes: Int?

    /// Número total de capítulos, `nil` si está en publicación.
    var chapters: Int?

    /// Fecha de inicio de publicación en formato ISO 8601.
    var startDate: String?

    /// Fecha de fin de publicación en formato ISO 8601.
    var endDate: String?

    /// Sinopsis del manga.
    var sypnosis: String?

    /// Información adicional sobre el manga.
    var background: String?

    /// URL de la imagen de portada.
    var mainPicture: String

    /// URL de la página del manga en MyAnimeList.
    var url: String

    /// Nombres de los autores (desnormalizado).
    var authorNames: [String]

    /// Nombres de los géneros (desnormalizado).
    var genreNames: [String]

    /// Nombres de los temas (desnormalizado).
    var themeNames: [String]

    /// Nombres de las demografías (desnormalizado).
    var demographicNames: [String]

    /// Fecha en que se cacheó el manga.
    var cachedAt: Date

    /// Entradas en colecciones de usuarios que contienen este manga.
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

    /// Crea un `MangaModel` desde un DTO de la API.
    ///
    /// Extrae y desnormaliza los datos relacionados (autores, géneros, etc.)
    /// para almacenarlos como arrays de strings.
    ///
    /// - Parameter manga: El DTO `Manga` recibido de la API.
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

    /// Convierte el modelo a un DTO `Manga` para usar en vistas.
    ///
    /// Reconstruye los objetos relacionados (Author, Genre, etc.) a partir
    /// de los arrays desnormalizados. Los IDs generados son temporales.
    ///
    /// - Returns: Un `Manga` compatible con las vistas existentes.
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

    /// URL limpia de la imagen de portada.
    var coverURL: URL? {
        URL(string: mainPicture.replacingOccurrences(of: "\"", with: ""))
    }
}

// MARK: - Preview Support
extension MangaModel {
    @MainActor
    static var preview: MangaModel {
        MangaModel(
            id: 1,
            title: "One Piece",
            titleEnglish: "One Piece",
            titleJapanese: "ワンピース",
            status: "Publishing",
            score: 9.2,
            volumes: 109,
            chapters: 1100,
            startDate: "1997-07-22",
            sypnosis: "Monkey D. Luffy sets off on an adventure...",
            mainPicture: "https://cdn.myanimelist.net/images/manga/2/253146.jpg",
            url: "https://myanimelist.net/manga/13/One_Piece",
            authorNames: ["Eiichiro Oda"],
            genreNames: ["Action", "Adventure", "Comedy"],
            themeNames: ["Pirates"],
            demographicNames: ["Shounen"]
        )
    }
}
