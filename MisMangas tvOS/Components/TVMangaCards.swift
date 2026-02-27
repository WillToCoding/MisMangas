//
//  TVMangaCards.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 25/2/26.
//

import SwiftUI

// MARK: - Hero Card Label (alternativo para grids)

struct TVHeroCardLabel: View {
    let manga: Manga
    var rank: Int = 0

    @State private var coverVM = MangaCoverVM()

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Imagen
            Group {
                if let image = coverVM.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .overlay {
                            if coverVM.isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
            }
            .frame(width: 500, height: 300)
            .clipped()

            // Gradiente
            LinearGradient(
                colors: [.clear, .black.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Rank
            if rank > 0 {
                Text("#\(rank)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.yellow.gradient, in: Capsule())
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            // Info
            VStack(alignment: .leading, spacing: 10) {
                Text(manga.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(manga.score.formatted(.number.precision(.fractionLength(1))))
                        .fontWeight(.semibold)
                    if let volumes = manga.volumes {
                        Text("•")
                        Text("\(volumes) vols")
                    }
                }
                .font(.system(size: 24))
                .foregroundStyle(.white.opacity(0.9))
            }
            .padding(24)
        }
        .frame(width: 500, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .task {
            coverVM.getImage(url: manga.coverURL)
        }
    }
}

// MARK: - Explore Card Label

struct TVExploreCardLabel: View {
    let manga: Manga

    @State private var coverVM = MangaCoverVM()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Portada
            Group {
                if let image = coverVM.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .overlay {
                            if coverVM.isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
            }
            .frame(width: 220, height: 330)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(manga.title)
                    .font(.system(size: 24, weight: .bold))
                    .lineLimit(1)
                    .frame(width: 220, alignment: .leading)

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(manga.score.formatted(.number.precision(.fractionLength(1))))
                        .fontWeight(.medium)
                }
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.gray.opacity(0.15)))
        .task {
            coverVM.getImage(url: manga.coverURL)
        }
    }
}

#Preview("Hero Card Label") {
    TVHeroCardLabel(manga: .test, rank: 1)
        .padding(40)
}

#Preview("Explore Card Label") {
    TVExploreCardLabel(manga: .test)
        .padding(40)
}
