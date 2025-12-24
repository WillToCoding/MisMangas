//
//  ReadingProgressIntent.swift
//  MisMangas
//
//  Created by Claude on 23/12/25.
//

import AppIntents
import Foundation

/// Intent para ver el progreso de lectura de todos los mangas
/// Trigger: "Oye Siri, mi progreso de lectura en MisMangas"
struct ReadingProgressIntent: AppIntent {
    static let title: LocalizedStringResource = "siri_progress_title"
    static let description = IntentDescription("siri_progress_description")

    static let openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let mangas = getReadingMangas()

        guard !mangas.isEmpty else {
            let noMangaMessage = String(localized: "siri_no_manga_reading")
            return .result(dialog: "\(noMangaMessage)")
        }

        if mangas.count == 1 {
            let manga = mangas[0]
            let singleFormat = String(localized: "siri_single_manga_format")
            let volumeInfo = manga.totalVolumes.map { String(localized: "siri_of_format", defaultValue: " of %d").replacingOccurrences(of: "%d", with: "\($0)") } ?? ""
            let message = String(format: singleFormat, manga.title, manga.currentVolume) + volumeInfo + "."
            return .result(dialog: "\(message)")
        }

        // Listar los primeros 3 mangas
        let topMangas = mangas.prefix(3)
        let countFormat = String(localized: "siri_manga_count_format")
        var response = String(format: countFormat, mangas.count)

        let atVolumeFormat = String(localized: "siri_at_volume_format")
        let mangaList = topMangas.map { manga -> String in
            if let total = manga.totalVolumes {
                return "\(manga.title) " + String(format: atVolumeFormat, manga.currentVolume, total)
            }
            return "\(manga.title) Vol. \(manga.currentVolume)"
        }.joined(separator: ", ")

        response += mangaList

        if mangas.count > 3 {
            let andMoreFormat = String(localized: "siri_and_more_format")
            response += String(format: andMoreFormat, mangas.count - 3)
        } else {
            response += "."
        }

        return .result(dialog: "\(response)")
    }

    private func getReadingMangas() -> [WidgetMangaIntent] {
        guard let defaults = UserDefaults(suiteName: "group.com.murtidev.MisMangas"),
              let data = defaults.data(forKey: "widgetMangaData"),
              let widgetData = try? JSONDecoder().decode(WidgetDataIntent.self, from: data) else {
            return []
        }
        return widgetData.mangas
    }
}
