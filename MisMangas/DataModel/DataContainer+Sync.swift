//
//  DataContainer+Sync.swift
//  MisMangas
//
//  Created by Juan Carlos on 26/2/26.
//

import Foundation
import SwiftData

// MARK: - Cloud Sync
//
// Extension de DataContainer para sincronizacion entre local (SwiftData) y cloud (API).
//
// ## Flujo de sincronizacion
//
// 1. Usuario modifica coleccion local → pendingSync = true
// 2. App carga coleccion cloud → detectConflicts()
// 3. Si hay conflicto → mostrar UI de resolucion
// 4. Usuario elige version → resolveConflict...()
// 5. markAsSynced() actualiza lastSynced*
//

extension DataContainer {

    /// Sincroniza un item de la coleccion cloud a local.
    ///
    /// Preserva datos locales que no existen en cloud (como `readingStatus`).
    /// Guarda `lastSynced*` para detectar conflictos futuros.
    ///
    /// - Parameter cloudItem: Item de la coleccion cloud.
    func syncFromCloud(_ cloudItem: UserMangaCollection) throws {
        let mangaId = cloudItem.manga.id
        let now = Date()

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
            existing.lastSyncDate = now
            existing.pendingSync = false
        } else {
            // Crear nueva entrada con datos de cloud
            let collection = UserCollection(
                manga: mangaModel,
                volumesOwned: cloudItem.volumesOwned,
                currentReadingVolume: cloudItem.readingVolume,
                hasCompleteCollection: cloudItem.completeCollection,
                readingStatus: cloudItem.completeCollection ? .completed : .reading,
                lastSyncDate: now,
                lastSyncedVolumes: cloudItem.volumesOwned,
                lastSyncedReadingVolume: cloudItem.readingVolume
            )
            modelContext.insert(collection)
        }

        if modelContext.hasChanges {
            try modelContext.save()
        }
    }

    /// Sincroniza toda la coleccion cloud a local.
    ///
    /// Itera sobre todos los items y llama a ``syncFromCloud(_:)``.
    /// No detecta conflictos, sobrescribe datos locales.
    ///
    /// - Parameter cloudCollection: Coleccion completa del cloud.
    func syncAllFromCloud(_ cloudCollection: [UserMangaCollection]) throws {
        for item in cloudCollection {
            try syncFromCloud(item)
        }
    }
}

// MARK: - Sync Management

extension DataContainer {

    /// Obtiene todos los items pendientes de sincronizar con cloud.
    ///
    /// - Returns: Array de ``PendingSyncItem`` con los items que tienen `pendingSync == true`.
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
                currentReadingVolume: collection.currentReadingVolume,
                lastModified: collection.lastModified,
                lastSyncDate: collection.lastSyncDate
            )
        }
    }

    /// Marca un item como sincronizado.
    ///
    /// Actualiza `lastSyncedVolumes` y `lastSyncedReadingVolume` con los valores actuales,
    /// y establece `pendingSync = false`.
    ///
    /// - Parameter mangaId: ID del manga a marcar.
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
            collection.lastSyncDate = Date()
            try modelContext.save()
        }
    }

    /// Limpia el flag `pendingSync` sin actualizar `lastSynced`.
    ///
    /// Usado cuando se descarta un cambio local antiguo.
    ///
    /// - Parameter mangaId: ID del manga.
    func clearPendingSync(mangaId: Int) throws {
        var fetch = FetchDescriptor<UserCollection>(
            predicate: #Predicate { $0.manga.id == mangaId }
        )
        fetch.fetchLimit = 1

        if let collection = try modelContext.fetch(fetch).first {
            collection.pendingSync = false
            try modelContext.save()
        }
    }

    /// Detecta conflictos entre local y cloud.
    ///
    /// Un conflicto ocurre cuando:
    /// 1. Local tiene cambios pendientes (`pendingSync == true`)
    /// 2. Cloud cambio desde la ultima sincronizacion
    /// 3. Los valores locales y cloud son diferentes
    ///
    /// - Parameter cloudCollection: Coleccion actual del cloud.
    /// - Returns: Array de ``SyncConflict`` con los conflictos detectados.
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

    /// Sincroniza cloud a local, omitiendo items con conflicto.
    ///
    /// Solo sincroniza items que no tienen `pendingSync == true`.
    /// Los items con cambios pendientes se omiten para evitar sobrescribir.
    ///
    /// - Parameter cloudCollection: Coleccion del cloud.
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
}

// MARK: - Conflict Resolution

extension DataContainer {

    /// Resuelve un conflicto eligiendo la version local.
    ///
    /// Mantiene `pendingSync = true` para que el ``CloudCollectionViewModel``
    /// suba los datos locales al cloud en la proxima sincronizacion.
    ///
    /// - Parameter mangaId: ID del manga en conflicto.
    func resolveConflictKeepLocal(mangaId: Int) throws {
        // El item local ya tiene pendingSync = true, solo necesitamos
        // que el CloudCollectionViewModel lo suba a cloud
        // No hacemos nada aquí, el pendingSync ya está marcado
    }

    /// Resuelve un conflicto eligiendo la version cloud.
    ///
    /// Sobrescribe los datos locales con los del cloud y
    /// establece `pendingSync = false`.
    ///
    /// - Parameters:
    ///   - mangaId: ID del manga en conflicto.
    ///   - cloudItem: Datos del cloud a usar.
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

/// Representa un conflicto entre datos locales y cloud.
///
/// Contiene los valores de ambas versiones para mostrar al usuario
/// y permitirle elegir cual mantener.
struct SyncConflict: Identifiable {
    let id = UUID()
    let mangaId: Int
    let mangaTitle: String
    let localVolumesOwned: [Int]
    let localReadingVolume: Int?
    let cloudVolumesOwned: [Int]
    let cloudReadingVolume: Int?
}

/// Item pendiente de sincronizar con cloud.
///
/// Representa un ``UserCollection`` con `pendingSync == true`.
struct PendingSyncItem {
    let mangaId: Int
    let mangaTitle: String
    let hasCompleteCollection: Bool
    let volumesOwned: [Int]
    let currentReadingVolume: Int?
    let lastModified: Date
    let lastSyncDate: Date

    /// `true` si el cambio local es más reciente que la última sincronización
    var hasRecentLocalChanges: Bool {
        lastModified > lastSyncDate
    }
}
