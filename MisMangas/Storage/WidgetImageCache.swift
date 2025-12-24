//
//  WidgetImageCache.swift
//  MisMangas
//
//  Created by Juan Carlos on 23/12/25.
//

import Foundation
import UIKit

@MainActor
final class WidgetImageCache {
    static let shared = WidgetImageCache()

    private let appGroupID = "group.com.murtidev.MisMangas"

    private var cacheDirectory: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("WidgetImages", isDirectory: true)
    }

    private init() {
        createCacheDirectoryIfNeeded()
    }

    private func createCacheDirectoryIfNeeded() {
        guard let directory = cacheDirectory else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// Descarga y guarda imagen, retorna path local
    func cacheImage(from urlString: String, for mangaId: Int) async -> String? {
        let cleanURL = urlString.replacingOccurrences(of: "\"", with: "")
        guard let url = URL(string: cleanURL),
              let cacheDirectory else { return nil }

        let localPath = cacheDirectory.appendingPathComponent("\(mangaId).jpg")

        // Si ya existe, retornar path
        if FileManager.default.fileExists(atPath: localPath.path) {
            return localPath.path
        }

        // Descargar imagen
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            try data.write(to: localPath)
            return localPath.path
        } catch {
            print("[WidgetImageCache] Error descargando imagen: \(error)")
            return nil
        }
    }

    /// Cachea múltiples imágenes
    func cacheImages(for mangas: [(id: Int, url: String)]) async -> [Int: String] {
        var results: [Int: String] = [:]

        await withTaskGroup(of: (Int, String?).self) { group in
            for manga in mangas {
                group.addTask {
                    let path = await self.cacheImage(from: manga.url, for: manga.id)
                    return (manga.id, path)
                }
            }

            for await (id, path) in group {
                if let path {
                    results[id] = path
                }
            }
        }

        return results
    }

    /// Limpia caché
    func clearCache() {
        guard let directory = cacheDirectory else { return }
        try? FileManager.default.removeItem(at: directory)
        createCacheDirectoryIfNeeded()
    }
}
