//
//  MangaCard.swift
//  MisMangas
//
//  Created by Juan Carlos on 2/2/26.
//

import SwiftUI

/// Card visual para mostrar un manga en secciones horizontales.
struct MangaCard: View {
    let manga: Manga
    let namespace: Namespace.ID
    var showBadge: Bool = false
    var badgeText: String = "New"

    private var coverURL: URL? {
        URL(string: manga.mainPicture.replacingOccurrences(of: "\"", with: ""))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Imagen con overlay de gradiente
            ZStack(alignment: .topTrailing) {
                MangaCoverView(url: coverURL, namespace: namespace, size: .medium)

                // Badge opcional (ej: "New", "Top 10")
                if showBadge {
                    Text(badgeText)
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.red, in: Capsule())
                        .padding(8)
                }

                // Indicador de score en la esquina
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.yellow)
                            Text(String(format: "%.1f", manga.score))
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.6), in: Capsule())
                        .padding(6)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Titulo
            Text(manga.title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 140, height: 36, alignment: .top)
                .padding(.top, 8)
        }
        .frame(width: 140)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(manga.title)
        .accessibilityHint(String(localized: "accessibility_double_tap_details"))
    }
}

// MARK: - Preview

#Preview {
    @Previewable @Namespace var namespace
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            MangaCard(manga: .test, namespace: namespace, showBadge: true, badgeText: "Top")
            MangaCard(manga: .test, namespace: namespace)
            MangaCard(manga: .test, namespace: namespace)
        }
        .padding()
    }
}
