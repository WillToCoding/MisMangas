//
//  WidgetManga.swift
//  MisMangas widget
//
//  Created by Juan Carlos on 23/12/25.
//

import Foundation
import SwiftUI

/// Modelo simplificado de manga para el widget
/// Debe ser Codable para guardarse en App Group
struct WidgetManga: Codable, Identifiable, Sendable {
    let id: Int
    let title: String
    let mainPicture: String
    let localImagePath: String?
    let currentVolume: Int
    let totalVolumes: Int?
    let score: Double
    let lastUpdated: Date

    var progressText: String {
        if let total = totalVolumes {
            return "Vol. \(currentVolume)/\(total)"
        }
        return "Vol. \(currentVolume)"
    }

    var progressPercentage: Double {
        guard let total = totalVolumes, total > 0 else { return 0 }
        return Double(currentVolume) / Double(total)
    }

    var imageURL: URL? {
        URL(string: mainPicture)
    }

    /// Carga imagen desde caché local o retorna nil
    var localImage: Image? {
        guard let path = localImagePath,
              let uiImage = UIImage(contentsOfFile: path) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
}

/// Datos compartidos entre App y Widget
struct WidgetData: Codable, Sendable {
    let mangas: [WidgetManga]
    let totalInCollection: Int
    let completedCount: Int
    let readingCount: Int
    let lastUpdated: Date

    /// Progreso global de lectura (promedio de todos los mangas leyendo)
    var overallProgress: Double {
        let validMangas = mangas.filter { $0.totalVolumes != nil }
        guard !validMangas.isEmpty else { return 0 }
        let total = validMangas.reduce(0.0) { $0 + $1.progressPercentage }
        return total / Double(validMangas.count)
    }

    static let empty = WidgetData(
        mangas: [],
        totalInCollection: 0,
        completedCount: 0,
        readingCount: 0,
        lastUpdated: Date()
    )

    /// Datos de ejemplo para placeholder/preview
    static let placeholder = WidgetData(
        mangas: [
            WidgetManga(
                id: 42,
                title: "Dragon Ball",
                mainPicture: "https://cdn.myanimelist.net/images/manga/1/267793l.jpg",
                localImagePath: nil,
                currentVolume: 15,
                totalVolumes: 42,
                score: 8.41,
                lastUpdated: Date()
            ),
            WidgetManga(
                id: 21,
                title: "One Piece",
                mainPicture: "https://cdn.myanimelist.net/images/manga/2/253146l.jpg",
                localImagePath: nil,
                currentVolume: 50,
                totalVolumes: 109,
                score: 9.21,
                lastUpdated: Date().addingTimeInterval(-3600)
            ),
            WidgetManga(
                id: 11,
                title: "Naruto",
                mainPicture: "https://cdn.myanimelist.net/images/manga/3/249658l.jpg",
                localImagePath: nil,
                currentVolume: 30,
                totalVolumes: 72,
                score: 8.07,
                lastUpdated: Date().addingTimeInterval(-7200)
            ),
            WidgetManga(
                id: 13,
                title: "One Punch-Man",
                mainPicture: "https://cdn.myanimelist.net/images/manga/3/80661l.jpg",
                localImagePath: nil,
                currentVolume: 12,
                totalVolumes: 29,
                score: 8.69,
                lastUpdated: Date().addingTimeInterval(-10800)
            ),
            WidgetManga(
                id: 14,
                title: "Berserk",
                mainPicture: "https://cdn.myanimelist.net/images/manga/1/157897l.jpg",
                localImagePath: nil,
                currentVolume: 20,
                totalVolumes: 41,
                score: 9.47,
                lastUpdated: Date().addingTimeInterval(-14400)
            ),
            WidgetManga(
                id: 15,
                title: "Death Note",
                mainPicture: "https://cdn.myanimelist.net/images/manga/1/258245l.jpg",
                localImagePath: nil,
                currentVolume: 8,
                totalVolumes: 12,
                score: 8.69,
                lastUpdated: Date().addingTimeInterval(-18000)
            )
        ],
        totalInCollection: 12,
        completedCount: 3,
        readingCount: 6,
        lastUpdated: Date()
    )
}
