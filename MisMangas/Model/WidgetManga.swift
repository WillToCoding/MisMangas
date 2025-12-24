//
//  WidgetManga.swift
//  MisMangas
//
//  Created by Juan Carlos on 23/12/25.
//

import Foundation

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
}

/// Datos compartidos entre App y Widget
struct WidgetData: Codable, Sendable {
    let mangas: [WidgetManga]
    let lastUpdated: Date
    let userEmail: String?

    static let empty = WidgetData(mangas: [], lastUpdated: Date(), userEmail: nil)
}
