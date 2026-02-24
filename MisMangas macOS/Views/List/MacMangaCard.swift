//
//  MacMangaCard.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 22/2/26.
//

import SwiftUI

/// Card visual para mostrar un manga en secciones horizontales (macOS).
struct MacMangaCard: View {
    let manga: Manga
    var showBadge: Bool = false
    var badgeText: String = "New"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Imagen con overlay
            ZStack(alignment: .topTrailing) {
                CachedCoverImage(
                    url: manga.coverURL,
                    width: 120,
                    height: 180,
                    cornerRadius: 12
                )

                // Badge opcional
                if showBadge {
                    Text(badgeText)
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.red, in: Capsule())
                        .padding(8)
                }

                // Score en la esquina
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.yellow)
                            Text(manga.score.formatted(.number.precision(.fractionLength(1))))
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.6), in: Capsule())
                        .padding(6)
                    }
                }
                .frame(width: 120, height: 180)
            }

            // Titulo
            Text(manga.title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 120, height: 36, alignment: .top)
                .padding(.top, 8)
        }
        .frame(width: 120)
    }
}

#Preview {
    HStack(spacing: 16) {
        MacMangaCard(manga: .test, showBadge: true, badgeText: "Top")
        MacMangaCard(manga: .test)
    }
    .padding()
}
