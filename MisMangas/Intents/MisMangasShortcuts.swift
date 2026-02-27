//
//  MisMangasShortcuts.swift
//  MisMangas
//
//  Created by Juan Carlos on 23/12/25.
//

import AppIntents

/// Registra los shortcuts de Siri para MisMangas
struct MisMangasShortcuts: AppShortcutsProvider {

    /// Shortcuts disponibles para Siri
    static var appShortcuts: [AppShortcut] {

        // 1. Ver manga actual
        AppShortcut(
            intent: ShowCurrentReadingIntent(),
            phrases: [
                "siri_phrase_current_1 \(.applicationName)",
                "siri_phrase_current_2 \(.applicationName)",
                "siri_phrase_current_3 \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("siri_current_manga"),
            systemImageName: "book.fill"
        )

        // 2. Ver progreso de lectura
        AppShortcut(
            intent: ReadingProgressIntent(),
            phrases: [
                "siri_phrase_progress_1 \(.applicationName)",
                "siri_phrase_progress_2 \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("siri_reading_progress"),
            systemImageName: "chart.bar.fill"
        )

        // 3. Abrir colección
        AppShortcut(
            intent: ShowCollectionIntent(),
            phrases: [
                "siri_phrase_collection_1 \(.applicationName)",
                "siri_phrase_collection_2 \(.applicationName)",
                "siri_phrase_collection_3 \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("siri_my_collection"),
            systemImageName: "books.vertical.fill"
        )
    }
}
