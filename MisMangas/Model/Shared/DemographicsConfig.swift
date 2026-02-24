//
//  DemographicsConfig.swift
//  MisMangas
//
//  Created by Claude on 23/02/26.
//

import SwiftUI

/// Configuración centralizada de demografías de manga.
/// Evita duplicación de este array en múltiples vistas.
@MainActor
enum DemographicsConfig {
    /// Lista de demografías con sus propiedades visuales.
    static let list: [(key: String, title: LocalizedStringKey, icon: String, color: Color)] = [
        ("Shounen", "section_shounen", "flame.fill", .orange),
        ("Seinen", "section_seinen", "person.fill", .purple),
        ("Shoujo", "section_shoujo", "heart.fill", .pink),
        ("Josei", "section_josei", "sparkles", .indigo),
        ("Kids", "section_kids", "star.fill", .yellow)
    ]

    /// Busca la configuración de una demografía por su key.
    static func config(for key: String) -> (key: String, title: LocalizedStringKey, icon: String, color: Color)? {
        list.first { $0.key == key }
    }

    /// Todas las keys de demografía disponibles.
    static var allKeys: [String] {
        list.map(\.key)
    }
}
