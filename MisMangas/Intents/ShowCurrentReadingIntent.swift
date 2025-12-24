//
//  ShowCurrentReadingIntent.swift
//  MisMangas
//
//  Created by Claude on 23/12/25.
//

import AppIntents
import Foundation

/// Intent para mostrar el manga que está leyendo el usuario
/// Trigger: "Oye Siri, ¿qué estoy leyendo en MisMangas?"
struct ShowCurrentReadingIntent: AppIntent {
    static let title: LocalizedStringResource = "siri_current_reading_title"
    static let description = IntentDescription("siri_current_reading_description")

    static let openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let currentManga = getCurrentReading() else {
            let noMangaMessage = String(localized: "siri_no_manga_reading")
            return .result(dialog: "\(noMangaMessage)")
        }

        let readingFormat = String(localized: "siri_reading_format")
        var message = String(format: readingFormat, currentManga.title, currentManga.currentVolume)

        if let total = currentManga.totalVolumes {
            let ofFormat = String(localized: "siri_of_format")
            message += String(format: ofFormat, total)
            let percentage = Int(currentManga.progressPercentage * 100)
            let progressFormat = String(localized: "siri_progress_format")
            message += String(format: progressFormat, percentage)
        }

        return .result(dialog: "\(message)")
    }

    /// Lee el manga actual desde App Group (mismo que el widget)
    private func getCurrentReading() -> WidgetMangaIntent? {
        guard let defaults = UserDefaults(suiteName: "group.com.murtidev.MisMangas"),
              let data = defaults.data(forKey: "widgetMangaData"),
              let widgetData = try? JSONDecoder().decode(WidgetDataIntent.self, from: data),
              let first = widgetData.mangas.first else {
            return nil
        }
        return first
    }
}

// MARK: - Modelos locales para el Intent (evita dependencias)

/// Modelo simplificado para el Intent
struct WidgetMangaIntent: Codable {
    let id: Int
    let title: String
    let currentVolume: Int
    let totalVolumes: Int?

    var progressPercentage: Double {
        guard let total = totalVolumes, total > 0 else { return 0 }
        return Double(currentVolume) / Double(total)
    }
}

struct WidgetDataIntent: Codable {
    let mangas: [WidgetMangaIntent]
    let lastUpdated: Date
    let userEmail: String?
}
