//
//  DemographicsConfig.swift
//  MisMangas
//
//  Created by Claude on 23/02/26.
//

import SwiftUI

/// Representa una sección de demografía con sus propiedades visuales.
struct DemographicSection: Identifiable {
    let id: String
    let title: LocalizedStringKey
    let icon: String
    let color: Color
}


/// Configuración centralizada de demografías de manga.
@MainActor
enum DemographicsConfig {
    static let list: [DemographicSection] = [
        DemographicSection(id: "Shounen", title: "section_shounen", icon: "flame.fill", color: .orange),
        DemographicSection(id: "Seinen", title: "section_seinen", icon: "person.fill", color: .purple),
        DemographicSection(id: "Shoujo", title: "section_shoujo", icon: "heart.fill", color: .pink),
        DemographicSection(id: "Josei", title: "section_josei", icon: "sparkles", color: .indigo),
        DemographicSection(id: "Kids", title: "section_kids", icon: "star.fill", color: .yellow)
    ]

    static func config(for id: String) -> DemographicSection? {
        list.first { $0.id == id }
    }

    static var allKeys: [String] {
        list.map(\.id)
    }
}
