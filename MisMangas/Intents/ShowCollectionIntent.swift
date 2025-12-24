//
//  ShowCollectionIntent.swift
//  MisMangas
//
//  Created by Claude on 23/12/25.
//

import AppIntents
import Foundation

/// Intent para abrir la app en la vista de colección
/// Trigger: "Oye Siri, mi colección de mangas"
struct ShowCollectionIntent: AppIntent {
    static let title: LocalizedStringResource = "siri_collection_title"
    static let description = IntentDescription("siri_collection_description")

    // Abre la app cuando se ejecuta
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // La app se abrirá automáticamente
        return .result()
    }
}
