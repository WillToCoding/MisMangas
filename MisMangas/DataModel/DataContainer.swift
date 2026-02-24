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
    /// - Parameter markPending: Si true, marca como pendiente de sync
    func addToCollection(
        manga: Manga,
        volumesOwned: [Int],
        currentReadingVolume: Int?,
        hasCompleteCollection: Bool,
        readingStatus: ReadingStatus = .planToRead,
        markPending: Bool = true
    ) throws {
        // Primero cachear el manga
        let mangaModel = try cacheManga(manga)

        // Verificar si ya existe en la colección
        let mangaId = manga.id
        var fetch = FetchDescriptor<UserCollection>(
            predicate: #Predicate { $0.manga.id == mangaId }
        )
        fetch.fetchLimit = 1

        let now = Date()

        if let existing = try modelContext.fetch(fetch).first {
            // Actualizar colección existente - eliminar volúmenes antiguos
            for vol in existing.ownedVolumes {
                modelContext.delete(vol)
            }
            existing.ownedVolumes = volumesOwned.map { OwnedVolume(number: $0) }
            existing.currentReadingVolume = currentReadingVolume
            existing.hasCompleteCollection = hasCompleteCollection
            existing.readingStatus = readingStatus
            existing.lastModified = now
            if markPending {
                existing.pendingSync = true
            }
        } else {
            // Crear nueva entrada en la colección
            let collection = UserCollection(
                manga: mangaModel,
                volumesOwned: volumesOwned,
                currentReadingVolume: currentReadingVolume,
                hasCompleteCollection: hasCompleteCollection,
                readingStatus: readingStatus,
                pendingSync: markPending,
                lastModified: now
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
    /// - Parameter markPending: Si true, marca como pendiente de sync (cambio local sin subir a cloud)
    func updateUserStats(
        mangaId: Int,
        readingStatus: ReadingStatus? = nil,
        currentVolume: Int? = nil,
        volumesOwned: [Int]? = nil,
        hasCompleteCollection: Bool? = nil,
        markPending: Bool = true
    ) throws {
        var fetch = FetchDescriptor<UserCollection>(
            predicate: #Predicate { $0.manga.id == mangaId }
        )
        fetch.fetchLimit = 1

        if let collection = try modelContext.fetch(fetch).first {
            if let status = readingStatus {
                collection.readingStatus = status
            }
            if let volume = currentVolume {
                collection.currentReadingVolume = volume
            }
            if let volumes = volumesOwned {
                // Eliminar volúmenes actuales
                for vol in collection.ownedVolumes {
                    modelContext.delete(vol)
                }
                // Crear nuevos volúmenes
                collection.ownedVolumes = volumes.map { OwnedVolume(number: $0) }
            }
            if let complete = hasCompleteCollection {
                collection.hasCompleteCollection = complete
            }

            // Marcar como modificado
            collection.lastModified = Date()
            if markPending {
                collection.pendingSync = true
            }

            try modelContext.save()
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
    /// Preserva datos locales que no existen en cloud (readingStatus)
    /// Guarda lastSynced para detectar conflictos futuros
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
            // Actualizar solo datos que vienen de cloud, preservar readingStatus local
            for vol in existing.ownedVolumes {
                modelContext.delete(vol)
            }
            existing.ownedVolumes = cloudItem.volumesOwned.map { OwnedVolume(number: $0) }
            existing.currentReadingVolume = cloudItem.readingVolume
            existing.hasCompleteCollection = cloudItem.completeCollection
            // Guardar snapshot de cloud para detectar conflictos
            existing.lastSyncedVolumes = cloudItem.volumesOwned
            existing.lastSyncedReadingVolume = cloudItem.readingVolume
            existing.pendingSync = false
        } else {
            // Crear nueva entrada con datos de cloud
            let collection = UserCollection(
                manga: mangaModel,
                volumesOwned: cloudItem.volumesOwned,
                currentReadingVolume: cloudItem.readingVolume,
                hasCompleteCollection: cloudItem.completeCollection,
                readingStatus: cloudItem.completeCollection ? .completed : .reading,
                lastSyncedVolumes: cloudItem.volumesOwned,
                lastSyncedReadingVolume: cloudItem.readingVolume
            )
            modelContext.insert(collection)
        }

        if modelContext.hasChanges {
            try modelContext.save()
        }
    }

    /// Sincroniza toda la colección cloud a local (sin conflictos)
    func syncAllFromCloud(_ cloudCollection: [UserMangaCollection]) throws {
        for item in cloudCollection {
            try syncFromCloud(item)
        }
    }

    // MARK: - Sync Management

    /// Obtiene todos los items pendientes de sincronizar con cloud
    func getPendingSyncItems() throws -> [PendingSyncItem] {
        let fetch = FetchDescriptor<UserCollection>(
            predicate: #Predicate { $0.pendingSync == true }
        )
        return try modelContext.fetch(fetch).map { collection in
            PendingSyncItem(
                mangaId: collection.manga.id,
                mangaTitle: collection.manga.title,
                hasCompleteCollection: collection.hasCompleteCollection,
                volumesOwned: collection.volumesOwned,
                currentReadingVolume: collection.currentReadingVolume
            )
        }
    }

    /// Marca un item como sincronizado (ya no tiene cambios pendientes)
    /// Actualiza lastSynced con los valores actuales
    func markAsSynced(mangaId: Int) throws {
        var fetch = FetchDescriptor<UserCollection>(
            predicate: #Predicate { $0.manga.id == mangaId }
        )
        fetch.fetchLimit = 1

        if let collection = try modelContext.fetch(fetch).first {
            collection.pendingSync = false
            // Guardar valores actuales como lastSynced
            collection.lastSyncedVolumes = collection.volumesOwned
            collection.lastSyncedReadingVolume = collection.currentReadingVolume
            try modelContext.save()
        }
    }

    /// Detecta conflictos entre local y cloud
    /// Conflicto = local tiene cambios pendientes Y cloud cambio desde ultima sync
    func detectConflicts(cloudCollection: [UserMangaCollection]) throws -> [SyncConflict] {
        var conflicts: [SyncConflict] = []

        for cloudItem in cloudCollection {
            let mangaId = cloudItem.manga.id
            var fetch = FetchDescriptor<UserCollection>(
                predicate: #Predicate { $0.manga.id == mangaId }
            )
            fetch.fetchLimit = 1

            if let local = try modelContext.fetch(fetch).first, local.pendingSync {
                // Local tiene cambios pendientes, verificar si cloud cambio desde lastSynced
                let lastSyncedVolumes = Set(local.lastSyncedVolumes)
                let cloudVolumes = Set(cloudItem.volumesOwned)
                let lastSyncedReading = local.lastSyncedReadingVolume
                let cloudReading = cloudItem.readingVolume

                // Valores actuales de local
                let localVolumes = Set(local.volumesOwned)
                let localReading = local.currentReadingVolume

                // Si local actual == cloud actual, no hay conflicto (mismo cambio en ambos)
                let localEqualsCloud = localVolumes == cloudVolumes && localReading == cloudReading
                if localEqualsCloud {
                    // Marcar como sincronizado, no hay conflicto
                    local.pendingSync = false
                    local.lastSyncedVolumes = cloudItem.volumesOwned
                    local.lastSyncedReadingVolume = cloudReading
                    continue
                }

                // Si cloud difiere de lastSynced, otro dispositivo lo modifico
                let cloudChanged = lastSyncedVolumes != cloudVolumes || lastSyncedReading != cloudReading

                if cloudChanged {
                    // Conflicto real: local cambio Y cloud cambio Y son diferentes
                    conflicts.append(SyncConflict(
                        mangaId: mangaId,
                        mangaTitle: local.manga.title,
                        localVolumesOwned: local.volumesOwned,
                        localReadingVolume: local.currentReadingVolume,
                        cloudVolumesOwned: cloudItem.volumesOwned,
                        cloudReadingVolume: cloudReading
                    ))
                }
                // Si cloud == lastSynced, no hay conflicto, solo subir local
            }
        }

        return conflicts
    }

    /// Sincroniza cloud a local, omitiendo items con conflicto
    func syncFromCloudSkippingConflicts(_ cloudCollection: [UserMangaCollection]) throws {
        for cloudItem in cloudCollection {
            let mangaId = cloudItem.manga.id
            var fetch = FetchDescriptor<UserCollection>(
                predicate: #Predicate { $0.manga.id == mangaId }
            )
            fetch.fetchLimit = 1

            // Si existe local con pendingSync, no sobrescribir (es conflicto)
            if let local = try modelContext.fetch(fetch).first, local.pendingSync {
                continue
            }

            // No hay conflicto, sincronizar normalmente
            try syncFromCloud(cloudItem)
        }
    }

    /// Resuelve un conflicto eligiendo la versión local (sube a cloud después)
    func resolveConflictKeepLocal(mangaId: Int) throws {
        // El item local ya tiene pendingSync = true, solo necesitamos
        // que el CloudCollectionViewModel lo suba a cloud
        // No hacemos nada aquí, el pendingSync ya está marcado
    }

    /// Resuelve un conflicto eligiendo la versión cloud
    func resolveConflictUseCloud(mangaId: Int, cloudItem: UserMangaCollection) throws {
        var fetch = FetchDescriptor<UserCollection>(
            predicate: #Predicate { $0.manga.id == mangaId }
        )
        fetch.fetchLimit = 1

        if let local = try modelContext.fetch(fetch).first {
            // Sobrescribir con datos de cloud
            for vol in local.ownedVolumes {
                modelContext.delete(vol)
            }
            local.ownedVolumes = cloudItem.volumesOwned.map { OwnedVolume(number: $0) }
            local.currentReadingVolume = cloudItem.readingVolume
            local.hasCompleteCollection = cloudItem.completeCollection
            local.pendingSync = false
            local.lastModified = Date()

            try modelContext.save()
        }
    }
}

// MARK: - Sync Types

/// Representa un conflicto entre datos locales y cloud
struct SyncConflict: Identifiable {
    let id = UUID()
    let mangaId: Int
    let mangaTitle: String
    let localVolumesOwned: [Int]
    let localReadingVolume: Int?
    let cloudVolumesOwned: [Int]
    let cloudReadingVolume: Int?
}

/// Item pendiente de sincronizar
struct PendingSyncItem {
    let mangaId: Int
    let mangaTitle: String
    let hasCompleteCollection: Bool
    let volumesOwned: [Int]
    let currentReadingVolume: Int?
}
