//
//  DataContainer.swift
//  MisMangas
//
//  Created by Juan Carlos on 1/2/26.
//

import SwiftUI
import SwiftData

/// Actor para operaciones de SwiftData en background.
///
/// `DataContainer` encapsula todas las operaciones CRUD de SwiftData
/// ejecutandolas fuera del hilo principal para no bloquear la UI.
///
/// ## Uso
///
/// ```swift
/// let container = DataContainer(modelContainer: modelContext.container)
///
/// // Cachear manga
/// try await container.cacheManga(manga)
///
/// // Agregar a coleccion
/// try await container.addToCollection(
///     manga: manga,
///     volumesOwned: [1, 2, 3],
///     currentReadingVolume: 2,
///     hasCompleteCollection: false
/// )
/// ```
///
/// ## Operaciones
///
/// | Categoria | Metodos |
/// |-----------|---------|
/// | Cache | ``cacheManga(_:)``, ``getCachedManga(id:)``, ``isMangaCached(id:)`` |
/// | Coleccion | ``addToCollection(manga:volumesOwned:currentReadingVolume:hasCompleteCollection:readingStatus:markPending:)``, ``removeFromCollection(mangaId:)`` |
/// | Lectura | ``updateReadingProgress(mangaId:currentVolume:)``, ``updateUserStats(mangaId:readingStatus:currentVolume:volumesOwned:hasCompleteCollection:markPending:)`` |
/// | Consulta | ``isInCollection(mangaId:)``, ``getCollectionEntry(mangaId:)`` |
///
/// - Note: Usa `@ModelActor` para acceso seguro a SwiftData desde cualquier hilo.
@ModelActor
actor DataContainer {

    // MARK: - Manga Caching

    /// Cachea un manga en SwiftData (o actualiza si ya existe).
    ///
    /// Si el manga ya existe (mismo ID), actualiza todos sus campos.
    /// Si no existe, crea un nuevo ``MangaModel``.
    ///
    /// - Parameter manga: Manga del dominio a cachear.
    /// - Returns: El ``MangaModel`` creado o actualizado.
    /// - Throws: Error de SwiftData si falla el guardado.
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

    /// Obtiene un manga cacheado por ID.
    ///
    /// - Parameter id: ID del manga en la API.
    /// - Returns: El ``MangaModel`` si existe, `nil` si no esta cacheado.
    func getCachedManga(id: Int) throws -> MangaModel? {
        var fetch = FetchDescriptor<MangaModel>(
            predicate: #Predicate { $0.id == id }
        )
        fetch.fetchLimit = 1
        return try modelContext.fetch(fetch).first
    }

    /// Verifica si un manga esta cacheado.
    ///
    /// - Parameter id: ID del manga en la API.
    /// - Returns: `true` si existe en cache local.
    func isMangaCached(id: Int) throws -> Bool {
        let fetch = FetchDescriptor<MangaModel>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetchCount(fetch) > 0
    }

    // MARK: - Collection Management

    /// Añade un manga a la coleccion del usuario.
    ///
    /// Si el manga ya existe en la coleccion, actualiza sus datos.
    /// Primero cachea el manga antes de agregarlo a la coleccion.
    ///
    /// - Parameters:
    ///   - manga: Manga a agregar.
    ///   - volumesOwned: Volumenes que posee el usuario.
    ///   - currentReadingVolume: Volumen actual de lectura.
    ///   - hasCompleteCollection: Si tiene la coleccion fisica completa.
    ///   - readingStatus: Estado de lectura.
    ///   - markPending: Si `true`, marca como pendiente de sincronizar con cloud.
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

    /// Elimina un manga de la coleccion.
    ///
    /// - Parameter mangaId: ID del manga a eliminar.
    /// - Note: El manga cacheado no se elimina, solo la entrada de coleccion.
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

    /// Actualiza el progreso de lectura.
    ///
    /// - Parameters:
    ///   - mangaId: ID del manga.
    ///   - currentVolume: Nuevo volumen actual de lectura.
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

    /// Actualiza los stats personales del usuario.
    ///
    /// Permite actualizar uno o varios campos de la entrada de coleccion.
    /// Solo se actualizan los campos que no son `nil`.
    ///
    /// - Parameters:
    ///   - mangaId: ID del manga.
    ///   - readingStatus: Nuevo estado de lectura (opcional).
    ///   - currentVolume: Nuevo volumen actual (opcional).
    ///   - volumesOwned: Nuevos volumenes poseidos (opcional).
    ///   - hasCompleteCollection: Si tiene coleccion completa (opcional).
    ///   - markPending: Si `true`, marca como pendiente de sincronizar con cloud.
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

    /// Verifica si un manga esta en la coleccion.
    ///
    /// - Parameter mangaId: ID del manga.
    /// - Returns: `true` si el manga tiene entrada en la coleccion.
    func isInCollection(mangaId: Int) throws -> Bool {
        let fetch = FetchDescriptor<UserCollection>(
            predicate: #Predicate { $0.manga.id == mangaId }
        )
        return try modelContext.fetchCount(fetch) > 0
    }

    /// Obtiene la entrada de coleccion para un manga.
    ///
    /// - Parameter mangaId: ID del manga.
    /// - Returns: La ``UserCollection`` si existe, `nil` si no esta en coleccion.
    func getCollectionEntry(mangaId: Int) throws -> UserCollection? {
        var fetch = FetchDescriptor<UserCollection>(
            predicate: #Predicate { $0.manga.id == mangaId }
        )
        fetch.fetchLimit = 1
        return try modelContext.fetch(fetch).first
    }
}
