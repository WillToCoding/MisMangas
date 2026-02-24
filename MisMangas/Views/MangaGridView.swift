//
//  MangaGridView.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct MangaGridView: View {
    let mangas: [Manga]
    let namespace: Namespace.ID

    // Columnas adaptativas: mínimo 150pt de ancho
    // iPad mostrará más columnas automáticamente
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(mangas) { manga in
                    NavigationLink(value: manga) {
                        MangaGridCell(manga: manga, namespace: namespace)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

// MARK: - Grid Cell
struct MangaGridCell: View {
    let manga: Manga
    let namespace: Namespace.ID

    private var coverURL: URL? { manga.coverURL }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Portada con caché y animación hero
            MangaCoverView(url: coverURL, namespace: namespace, size: .medium)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .accessibilityHidden(true)

            // Título
            Text(manga.title)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.primary)

            // Score
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text(manga.score.formatted(.number.precision(.fractionLength(1))))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                // Volúmenes (si están disponibles)
                if let volumes = manga.volumes {
                    Text("stats_vols \(volumes)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityHidden(true)
        }
        .frame(width: 150)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(String(localized: "accessibility_double_tap_details"))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var label = manga.title
        label += ", " + String(localized: "accessibility_score \(manga.score.formatted(.number.precision(.fractionLength(1))))")

        if let volumes = manga.volumes {
            label += ", \(volumes) " + String(localized: "accessibility_volumes")
        }

        return label
    }
}

// MARK: - Preview
#Preview("Grid con mangas") {
    @Previewable @Namespace var namespace
    NavigationStack {
        MangaGridView(mangas: [
            .test,
            .test,
            .test,
            .test,
            .test,
            .test
        ], namespace: namespace)
    }
}

#Preview("Single Cell") {
    @Previewable @Namespace var namespace
    MangaGridCell(manga: .test, namespace: namespace)
        .padding()
}
