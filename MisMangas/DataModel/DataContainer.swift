//
//  DataContainer.swift
//  MisMangas
//
//  Created by Juan Carlos on 1/2/26.
//

import SwiftUI
import SwiftData

/// Actor para operaciones de SwiftData en background
/// Maneja el cacheo de mangas y la gestión de la colección
@ModelActor
actor DataContainer {

    // MARK: - Manga Caching

    /// Cachea un manga en SwiftData (o actualiza si ya existe)
    @discardableResult
    func cacheManga(_ manga: Manga) throws -> MangaModel {
        let mangaId = manga.id

        // Buscar si ya existe
        var fetch = FetchDescriptor<MangaModel>(
            predicate: #Predicate { $0.id == mangaId }
        )
        fetch.fetchLimit = 1

        if let existing = try modelContext.fetch(fetch).first {
            // Actualizar datos existentes
            existing.title = manga.title
            existing.titleEnglish = manga.titleEnglish
            existing.titleJapanese = manga.titleJapanese
            existing.status = manga.status
            existing.score = manga.score
            existing.volumes = manga.volumes
            existing.chapters = manga.chapters
            existing.startDate = manga.startDate
            existing.endDate = manga.endDate
            existing.sypnosis = manga.sypnosis
            existing.background = manga.background
            existing.mainPicture = manga.mainPicture
            existing.url = manga.url
            existing.authorNames = manga.authors.map { "\($0.firstName) \($0.lastName)".trimmingCharacters(in: .whitespaces) }
            existing.genreNames = manga.genres.map(\.genre)
            existing.themeNames = manga.themes.map(\.theme)
            existing.demographicNames = manga.demographics.map(\.demographic)
            existing.cachedAt = Date()

            if modelContext.hasChanges {
                try modelContext.save()
            }
            return existing
        } else {
            // Crear nuevo
            let mangaModel = MangaModel(from: manga)
            modelContext.insert(mangaModel)
            try modelContext.save()
            return mangaModel
        }
    }

    /// Obtiene un manga cacheado por ID
    func getCachedManga(id: Int) throws -> MangaModel? {
        var fetch = FetchDescriptor<MangaModel>(
            predicate: #Predicate { $0.id == id }
        )
        fetch.fetchLimit = 1
        return try modelContext.fetch(fetch).first
    }

    /// Verifica si un manga está cacheado
    func isMangaCached(id: Int) throws -> Bool {
        let fetch = FetchDescriptor<MangaModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetchCount(fetch) > 0
    }

    // MARK: - Collection Management

    /// Añade un manga a la colección del usuario
    func addToCollection(
        manga: Manga,
        volumesOwned: [Int],
        currentReadingVolume: Int?,
        currentChapter: Int? = nil,
        hasCompleteCollection: Bool,
        userScore: Double? = nil,
        readingStatus: ReadingStatus = .planToRead
    ) throws {
        // Primero cachear el manga
        let mangaModel = try cacheManga(manga)

        // Verificar si ya existe en la colección
        let mangaId = manga.id
        var fetch = FetchDescriptor<UserCollection>(
            predicate: #Predicate { $0.manga.id == mangaId }
        )
        fetch.fetchLimit = 1

        if let existing = try modelContext.fetch(fetch).first {
            // Actualizar colección existente
            existing.volumesOwned = volumesOwned
            existing.currentReadingVolume = currentReadingVolume
            existing.currentChapter = currentChapter
            existing.hasCompleteCollection = hasCompleteCollection
            existing.userScore = userScore
            existing.readingStatus = readingStatus
        } else {
            // Crear nueva entrada en la colección
            let collection = UserCollection(
                manga: mangaModel,
                volumesOwned: volumesOwned,
                currentReadingVolume: currentReadingVolume,
                currentChapter: currentChapter,
                hasCompleteCollection: hasCompleteCollection,
                userScore: userScore,
                readingStatus: readingStatus
            )
            modelContext.insert(collection)
        }

        if modelContext.hasChanges {
            try modelContext.save()
        }
    }

    /// Elimina un manga de la colección
    func removeFromCollection(mangaId: Int) throws {
        var fetch = FetchDescriptor<UserCollection>(
            predicate: #Predicate { $0.manga.id == mangaId }
        )
        fetch.fetchLimit = 1

        if let collection = try modelContext.fetch(fetch).first {
            modelContext.delete(collection)
            try modelContext.save()
        }
    }

    /// Actualiza el progreso de lectura
    func updateReadingProgress(mangaId: Int, currentVolume: Int) throws {
        var fetch = FetchDescriptor<UserCollection>(
            predicate: #Predicate { $0.manga.id == mangaId }
        )
        fetch.fetchLimit = 1

        if let collection = try modelContext.fetch(fetch).first {
            collection.currentReadingVolume = currentVolume
            try modelContext.save()
        }
    }

    /// Actualiza los stats personales del usuario
    func updateUserStats(
        mangaId: Int,
        userScore: Double? = nil,
        readingStatus: ReadingStatus? = nil,
        currentChapter: Int? = nil,
        currentVolume: Int? = nil,
        volumesOwned: [Int]? = nil
    ) throws {
        var fetch = FetchDescriptor<UserCollection>(
            predicate: #Predicate { $0.manga.id == mangaId }
        )
        fetch.fetchLimit = 1

        if let collection = try modelContext.fetch(fetch).first {
            if let score = userScore {
                collection.userScore = score
            }
            if let status = readingStatus {
                collection.readingStatus = status
            }
            if let chapter = currentChapter {
                collection.currentChapter = chapter
            }
            if let volume = currentVolume {
                collection.currentReadingVolume = volume
            }
            if let volumes = volumesOwned {
                collection.volumesOwned = volumes
                collection.hasCompleteCollection = collection.manga.volumes.map { volumes.count >= $0 } ?? false
            }

            if modelContext.hasChanges {
                try modelContext.save()
            }
        }
    }

    /// Verifica si un manga está en la colección
    func isInCollection(mangaId: Int) throws -> Bool {
        let fetch = FetchDescriptor<UserCollection>(
            predicate: #Predicate { $0.manga.id == mangaId }
        )
        return try modelContext.fetchCount(fetch) > 0
    }

    /// Obtiene la entrada de colección para un manga
    func getCollectionEntry(mangaId: Int) throws -> UserCollection? {
        var fetch = FetchDescriptor<UserCollection>(
            predicate: #Predicate { $0.manga.id == mangaId }
        )
        fetch.fetchLimit = 1
        return try modelContext.fetch(fetch).first
    }

    // MARK: - Cloud Sync

    /// Sincroniza un item de la colección cloud a local
    /// Preserva datos locales que no existen en cloud (userScore, readingStatus, currentChapter)
    func syncFromCloud(_ cloudItem: UserMangaCollection) throws {
        let mangaId = cloudItem.manga.id

        // Primero cachear el manga
        let mangaModel = try cacheManga(cloudItem.manga)

        // Buscar si ya existe en la colección local
        var fetch = FetchDescriptor<UserCollection>(
            predicate: #Predicate { $0.manga.id == mangaId }
        )
        fetch.fetchLimit = 1

        if let existing = try modelContext.fetch(fetch).first {
            // Actualizar solo datos que vienen de cloud, preservar datos locales
            existing.volumesOwned = cloudItem.volumesOwned
            existing.currentReadingVolume = cloudItem.readingVolume
            existing.hasCompleteCollection = cloudItem.completeCollection
            // Preservar: userScore, readingStatus, currentChapter (datos locales)
        } else {
            // Crear nueva entrada con datos de cloud
            let collection = UserCollection(
                manga: mangaModel,
                volumesOwned: cloudItem.volumesOwned,
                currentReadingVolume: cloudItem.readingVolume,
                hasCompleteCollection: cloudItem.completeCollection,
                readingStatus: cloudItem.completeCollection ? .completed : .reading
            )
            modelContext.insert(collection)
        }

        if modelContext.hasChanges {
            try modelContext.save()
        }
    }

    /// Sincroniza toda la colección cloud a local
    func syncAllFromCloud(_ cloudCollection: [UserMangaCollection]) throws {
        for item in cloudCollection {
            try syncFromCloud(item)
        }
    }
}
