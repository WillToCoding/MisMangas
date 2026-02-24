//
//  SharedData.swift
//  MisMangas
//
//  Created by Juan Carlos on 23/12/25.
//

import Foundation
import WidgetKit

/// Gestiona los datos compartidos entre App y Widget via App Groups
@MainActor
final class SharedData {
    static let shared = SharedData()

    private let appGroupID = "group.com.murtidev.MisMangas"
    private let widgetDataKey = "widgetMangaData"
    private let lastUpdatedKey = "mangaLastUpdated"

    // Cache local de fechas de última actualización por manga ID
    private var lastUpdatedDates: [Int: Date] = [:]

    private init() {
        loadLastUpdatedDates()
    }

    // MARK: - Last Updated Dates

    private func loadLastUpdatedDates() {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: lastUpdatedKey),
              let decoded = try? JSONDecoder().decode([Int: Date].self, from: data) else {
            return
        }
        lastUpdatedDates = decoded
    }

    private func saveLastUpdatedDates() {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let encoded = try? JSONEncoder().encode(lastUpdatedDates) else {
            return
        }
        defaults.set(encoded, forKey: lastUpdatedKey)
    }

    func updateMangaDate(_ mangaId: Int) {
        lastUpdatedDates[mangaId] = Date()
        saveLastUpdatedDates()
    }

    // MARK: - Save Data

    func saveWidgetData(_ data: WidgetData) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            print("[SharedData] Error: No se pudo acceder a App Group")
            return
        }

        do {
            let encoded = try JSONEncoder().encode(data)
            defaults.set(encoded, forKey: widgetDataKey)
            print("[SharedData] Widget data guardada: \(data.mangas.count) mangas")
        } catch {
            print("[SharedData] Error guardando widget data: \(error)")
        }
    }

    // MARK: - Update from Collection

    func updateWidgetFromCollection(_ collection: [UserMangaCollection], userEmail: String?) async {
        // Filtrar mangas con volumen de lectura
        let mangasConLectura = collection.filter { $0.readingVolume != nil }

        // Cachear imágenes
        let mangasParaCachear = mangasConLectura.map { (id: $0.manga.id, url: $0.manga.mainPicture) }
        let cachedPaths = await WidgetImageCache.shared.cacheImages(for: mangasParaCachear)

        // Crear WidgetMangas con paths locales y fechas
        let widgetMangas = mangasConLectura.compactMap { item -> WidgetManga? in
            guard let readingVolume = item.readingVolume else { return nil }

            // Usar fecha guardada o fecha antigua por defecto
            let lastUpdated = lastUpdatedDates[item.manga.id] ?? Date.distantPast

            return WidgetManga(
                id: item.manga.id,
                title: item.manga.title,
                mainPicture: item.manga.coverURL?.absoluteString ?? "",
                localImagePath: cachedPaths[item.manga.id],
                currentVolume: readingVolume,
                totalVolumes: item.manga.volumes,
                score: item.manga.score,
                lastUpdated: lastUpdated
            )
        }

        // Ordenar por fecha de última actualización (más reciente primero)
        let sortedMangas = widgetMangas.sorted { $0.lastUpdated > $1.lastUpdated }
        let limitedMangas = Array(sortedMangas.prefix(10))

        let widgetData = WidgetData(
            mangas: limitedMangas,
            lastUpdated: Date(),
            userEmail: userEmail
        )

        saveWidgetData(widgetData)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Clear Data

    func clearWidgetData() {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.removeObject(forKey: widgetDataKey)
        WidgetImageCache.shared.clearCache()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
