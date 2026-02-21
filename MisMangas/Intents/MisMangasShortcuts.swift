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
                "¿Qué estoy leyendo en \(.applicationName)?",
                "Mi manga actual en \(.applicationName)",
                "¿Qué manga leo en \(.applicationName)?",
                "¿Por dónde voy en \(.applicationName)?",
                "Manga actual de \(.applicationName)"
            ],
            shortTitle: "Manga Actual",
            systemImageName: "book.fill"
        )

        // 2. Ver progreso de lectura
        AppShortcut(
            intent: ReadingProgressIntent(),
            phrases: [
                "Mi progreso de lectura en \(.applicationName)",
                "¿Cuántos mangas leo en \(.applicationName)?",
                "Progreso de \(.applicationName)",
                "Mis lecturas en \(.applicationName)"
            ],
            shortTitle: "Progreso de Lectura",
            systemImageName: "chart.bar.fill"
        )

        // 3. Abrir colección
        AppShortcut(
            intent: ShowCollectionIntent(),
            phrases: [
                "Mi colección de mangas en \(.applicationName)",
                "Abrir mi colección en \(.applicationName)",
                "Ver colección de \(.applicationName)",
                "Mostrar \(.applicationName)"
            ],
            shortTitle: "Mi Colección",
            systemImageName: "books.vertical.fill"
        )
    }
}
