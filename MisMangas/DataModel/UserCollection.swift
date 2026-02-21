//
//  UserCollection.swift
//  MisMangas
//
//  Created by Juan Carlos on 1/2/26.
//

import Foundation
import SwiftData

/// Entrada en la colección del usuario
/// Contiene datos específicos de la colección (volúmenes, progreso, puntuación personal)
/// con relación al manga cacheado
@Model
final class UserCollection {
    // Relación al manga cacheado
    @Relationship var manga: MangaModel

    // Datos de la colección del usuario
    var volumesOwned: [Int]
    var currentReadingVolume: Int?
    var currentChapter: Int?
    var hasCompleteCollection: Bool
    var addedDate: Date

    // Datos personales del usuario
    var userScore: Double?
    var readingStatusRaw: String

    /// Estado de lectura del usuario
    var readingStatus: ReadingStatus {
        get { ReadingStatus(rawValue: readingStatusRaw) ?? .planToRead }
        set { readingStatusRaw = newValue.rawValue }
    }

    init(
        manga: MangaModel,
        volumesOwned: [Int] = [],
        currentReadingVolume: Int? = nil,
        currentChapter: Int? = nil,
        hasCompleteCollection: Bool = false,
        addedDate: Date = Date(),
        userScore: Double? = nil,
        readingStatus: ReadingStatus = .planToRead
    ) {
        self.manga = manga
        self.volumesOwned = volumesOwned
        self.currentReadingVolume = currentReadingVolume
        self.currentChapter = currentChapter
        self.hasCompleteCollection = hasCompleteCollection
        self.addedDate = addedDate
        self.userScore = userScore
        self.readingStatusRaw = readingStatus.rawValue
    }
}

// MARK: - Computed Properties para acceso fácil
extension UserCollection {
    var id: Int { manga.id }
    var title: String { manga.title }
    var titleEnglish: String? { manga.titleEnglish }
    var mainPicture: String { manga.mainPicture }
    var score: Double { manga.score }
    var totalVolumes: Int? { manga.volumes }
    var totalChapters: Int? { manga.chapters }
}

// MARK: - CollectionItem Protocol Conformance
extension UserCollection: CollectionItem {
    var collectionTitle: String { manga.title }

    var collectionCoverURL: URL? {
        URL(string: manga.mainPicture.replacingOccurrences(of: "\"", with: ""))
    }

    var collectionScore: Double { manga.score }
    var collectionUserScore: Double? { userScore }
    var collectionVolumesOwned: [Int] { volumesOwned }
    var collectionTotalVolumes: Int? { manga.volumes }
    var collectionReadingVolume: Int? { currentReadingVolume }
    var collectionCurrentChapter: Int? { currentChapter }
    var collectionTotalChapters: Int? { manga.chapters }
    var collectionIsComplete: Bool { hasCompleteCollection }
    var collectionReadingStatus: ReadingStatus { readingStatus }
    var isCloudSynced: Bool { false }
}
