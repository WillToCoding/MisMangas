//
//  MangaRow.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI

struct MangaRow: View {
    let manga: Manga
    let namespace: Namespace.ID

    private var coverURL: URL? { manga.coverURL }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MangaCoverView(url: coverURL, namespace: namespace, size: .small)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(manga.title)
                    .font(.headline)
                    .lineLimit(2)

                if let englishTitle = manga.titleEnglish, englishTitle != manga.title {
                    Text(englishTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    Label("\(manga.score, specifier: "%.2f")", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .accessibilityHidden(true)

                    if let volumes = manga.volumes {
                        Text("separator_dot")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)

                        Text("stats_vols \(volumes)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                }

                if !manga.genres.isEmpty {
                    Text(manga.genres.prefix(3).map(\.genre).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(String(localized: "accessibility_double_tap_details"))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var label = manga.title

        if let englishTitle = manga.titleEnglish, englishTitle != manga.title {
            label += ", \(englishTitle)"
        }

        label += ", " + String(localized: "accessibility_score \(manga.score.formatted(.number.precision(.fractionLength(1))))")

        if let volumes = manga.volumes {
            label += ", \(volumes) " + String(localized: "accessibility_volumes")
        }

        if !manga.genres.isEmpty {
            let genreNames = manga.genres.prefix(3).map(\.genre).joined(separator: ", ")
            label += ", " + String(localized: "accessibility_genres") + ": \(genreNames)"
        }

        return label
    }
}

#Preview {
    @Previewable @Namespace var namespace
    MangaRow(manga: .test, namespace: namespace)
}
