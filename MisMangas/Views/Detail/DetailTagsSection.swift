//
//  DetailTagsSection.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI

/// Sección reutilizable para mostrar tags (géneros, temas, demografías)
struct DetailTagsSection<T: Identifiable>: View {
    let title: LocalizedStringKey
    let items: [T]
    let color: Color
    let getText: (T) -> String

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h2)

                FlowLayout(spacing: 8) {
                    ForEach(items) { item in
                        TagChip(text: localizedAPIValue(getText(item)), color: color)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityText)
            }
        }
    }

    private var accessibilityText: String {
        items.map { localizedAPIValue(getText($0)) }.joined(separator: ", ")
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundStyle(.primary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color, lineWidth: 1))
    }
}

// MARK: - Convenience initializers for common types
extension DetailTagsSection where T == Genre {
    init(genres: [Genre]) {
        self.init(
            title: "detail_genres",
            items: genres,
            color: .blue,
            getText: { $0.genre }
        )
    }
}

extension DetailTagsSection where T == Theme {
    init(themes: [Theme]) {
        self.init(
            title: "detail_themes",
            items: themes,
            color: .purple,
            getText: { $0.theme }
        )
    }
}

extension DetailTagsSection where T == Demographic {
    init(demographics: [Demographic]) {
        self.init(
            title: "detail_demographics",
            items: demographics,
            color: .green,
            getText: { $0.demographic }
        )
    }
}

#Preview("Genres") {
    DetailTagsSection(genres: Manga.test.genres)
        .padding()
}

#Preview("Themes") {
    DetailTagsSection(themes: Manga.test.themes)
        .padding()
}
