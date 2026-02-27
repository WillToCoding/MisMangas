//
//  UserCollection.swift
//  MisMangas
//
//  Created by Juan Carlos on 1/2/26.
//

import Foundation
import SwiftData

// MARK: - OwnedVolume Model

/// Representa un volumen que el usuario posee.
@Model
final class OwnedVolume {
    /// Número del volumen.
    var number: Int

    /// Colección a la que pertenece este volumen.
    @Relationship var collection: UserCollection?

    init(number: Int) {
        self.number = number
    }
}

// MARK: - UserCollection Model

/// Entrada en la colección personal del usuario.
///
/// ## Overview
/// `UserCollection` representa un manga en la colección del usuario con sus datos
/// de seguimiento: volúmenes poseídos y progreso de lectura.
///
/// Tiene una relación con ``MangaModel`` que contiene los datos del manga cacheado.
///
/// ## Topics
///
/// ### Progreso de lectura
/// - ``currentReadingVolume``
/// - ``readingStatus``
///
/// ### Colección física
/// - ``ownedVolumes``
/// - ``hasCompleteCollection``
@Model
final class UserCollection {
    /// Manga asociado a esta entrada de colección.
    @Relationship var manga: MangaModel

    /// Volúmenes que posee el usuario.
    @Relationship(deleteRule: .cascade, inverse: \OwnedVolume.collection)
    var ownedVolumes: [OwnedVolume]

    /// Volumen que el usuario está leyendo actualmente.
    var currentReadingVolume: Int?

    /// Indica si el usuario tiene la colección física completa.
    var hasCompleteCollection: Bool

    /// Fecha en que se añadió el manga a la colección.
    var addedDate: Date = Date()

    /// Valor raw del estado de lectura para persistencia.
    var readingStatusRaw: String = ReadingStatus.planToRead.rawValue

    /// Indica si hay cambios locales pendientes de sincronizar con cloud.
    var pendingSync: Bool = false

    /// Fecha de última modificación local (para detectar conflictos).
    var lastModified: Date = Date()

    /// Fecha de última sincronización exitosa con cloud.
    var lastSyncDate: Date = Date.distantPast

    /// Volúmenes que tenía cloud la última vez que sincronizamos (comma-separated).
    var lastSyncedVolumesRaw: String

    /// Volumen de lectura que tenía cloud la última vez que sincronizamos.
    var lastSyncedReadingVolume: Int?

    /// Volúmenes sincronizados con cloud (computed).
    var lastSyncedVolumes: [Int] {
        get {
            guard !lastSyncedVolumesRaw.isEmpty else { return [] }
            return lastSyncedVolumesRaw.split(separator: ",").compactMap { Int($0) }
        }
        set {
            lastSyncedVolumesRaw = newValue.map(String.init).joined(separator: ",")
        }
    }

    /// Estado de lectura del manga.
    ///
    /// Los valores posibles son: `reading`, `completed`, `onHold`, `dropped`, `planToRead`.
    var readingStatus: ReadingStatus {
        get { ReadingStatus(rawValue: readingStatusRaw) ?? .planToRead }
        set { readingStatusRaw = newValue.rawValue }
    }

    /// Lista de números de volúmenes poseídos (computed para compatibilidad).
    var volumesOwned: [Int] {
        ownedVolumes.map(\.number).sorted()
    }

    init(
        manga: MangaModel,
        ownedVolumes: [OwnedVolume] = [],
        currentReadingVolume: Int? = nil,
        hasCompleteCollection: Bool = false,
        addedDate: Date = Date(),
        readingStatus: ReadingStatus = .planToRead,
        pendingSync: Bool = false,
        lastModified: Date = Date(),
        lastSyncDate: Date = Date.distantPast,
        lastSyncedVolumes: [Int] = [],
        lastSyncedReadingVolume: Int? = nil
    ) {
        self.manga = manga
        self.ownedVolumes = ownedVolumes
        self.currentReadingVolume = currentReadingVolume
        self.hasCompleteCollection = hasCompleteCollection
        self.addedDate = addedDate
        self.readingStatusRaw = readingStatus.rawValue
        self.pendingSync = pendingSync
        self.lastModified = lastModified
        self.lastSyncDate = lastSyncDate
        self.lastSyncedVolumesRaw = lastSyncedVolumes.map(String.init).joined(separator: ",")
        self.lastSyncedReadingVolume = lastSyncedReadingVolume
    }

    /// Convenience initializer con array de Int para volúmenes.
    convenience init(
        manga: MangaModel,
        volumesOwned: [Int],
        currentReadingVolume: Int? = nil,
        hasCompleteCollection: Bool = false,
        addedDate: Date = Date(),
        readingStatus: ReadingStatus = .planToRead,
        pendingSync: Bool = false,
        lastModified: Date = Date(),
        lastSyncDate: Date = Date.distantPast,
        lastSyncedVolumes: [Int] = [],
        lastSyncedReadingVolume: Int? = nil
    ) {
        let volumes = volumesOwned.map { OwnedVolume(number: $0) }
        self.init(
            manga: manga,
            ownedVolumes: volumes,
            currentReadingVolume: currentReadingVolume,
            hasCompleteCollection: hasCompleteCollection,
            addedDate: addedDate,
            readingStatus: readingStatus,
            pendingSync: pendingSync,
            lastModified: lastModified,
            lastSyncDate: lastSyncDate,
            lastSyncedVolumes: lastSyncedVolumes,
            lastSyncedReadingVolume: lastSyncedReadingVolume
        )
    }
}

// MARK: - Computed Properties

extension UserCollection {
    /// ID del manga asociado.
    var id: Int { manga.id }

    /// Título del manga asociado.
    var title: String { manga.title }

    /// Título en inglés del manga asociado.
    var titleEnglish: String? { manga.titleEnglish }

    /// URL de la portada del manga asociado.
    var mainPicture: String { manga.mainPicture }

    /// Puntuación media del manga asociado.
    var score: Double { manga.score }

    /// Total de volúmenes del manga, `nil` si está en publicación.
    var totalVolumes: Int? { manga.volumes }
}

// MARK: - CollectionItem Protocol Conformance
extension UserCollection: CollectionItem {
    var collectionTitle: String { manga.title }
    var collectionTitleJapanese: String? { manga.titleJapanese }
    var collectionCoverURL: URL? { manga.coverURL }
    var collectionScore: Double { manga.score }
    var collectionVolumesOwned: [Int] { volumesOwned }
    var collectionTotalVolumes: Int? { manga.volumes }
    var collectionTotalChapters: Int? { manga.chapters }
    var collectionReadingVolume: Int? { currentReadingVolume }
    var collectionIsComplete: Bool { hasCompleteCollection }
    var collectionReadingStatus: ReadingStatus { readingStatus }
    var collectionStatus: String { manga.status }
    var collectionSynopsis: String? { manga.sypnosis }
    var collectionGenres: [String] { manga.genreNames }
    var collectionMangaId: Int { manga.id }
    var isCloudSynced: Bool { false }  // Local collection is never "cloud"
}

// MARK: - Preview Support
extension UserCollection {
    @MainActor
    static var preview: UserCollection {
        UserCollection(
            manga: .preview,
            volumesOwned: [1, 2, 3, 4, 5],
            currentReadingVolume: 3,
            hasCompleteCollection: false,
            readingStatus: .reading
        )
    }
}
