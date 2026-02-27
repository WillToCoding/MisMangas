//
//  VisionHeroCarousel.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 26/02/26.
//

import SwiftUI

// MARK: - Hero Carousel

struct VisionHeroCarousel: View {
    let mangas: [Manga]
    @State private var selectedIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Label("section_best_rated", systemImage: "trophy.fill")
                .font(.largeTitle.bold())
                .foregroundStyle(.yellow)
                .padding(.horizontal, 60)

            TabView(selection: $selectedIndex) {
                ForEach(Array(mangas.enumerated()), id: \.element.id) { index, manga in
                    NavigationLink(value: manga) {
                        VisionHeroCard(manga: manga, rank: index + 1)
                    }
                    .buttonStyle(.plain)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 450)
        }
    }
}

// MARK: - Hero Card

struct VisionHeroCard: View {
    let manga: Manga
    var rank: Int = 0

    @State private var coverVM = MangaCoverVM()

    var body: some View {
        HStack(spacing: 50) {
            // Cover
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
            .frame(width: 280, height: 400)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 20)

            // Info
            VStack(alignment: .leading, spacing: 20) {
                // Rank badge
                if rank > 0 {
                    Text("#\(rank)")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.yellow.gradient, in: Capsule())
                }

                Text(manga.title)
                    .font(.system(size: 40, weight: .bold))
                    .lineLimit(2)

                if let titleJapanese = manga.titleJapanese {
                    Text(titleJapanese)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 24) {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text(manga.score.formatted(.number.precision(.fractionLength(1))))
                            .fontWeight(.bold)
                    }

                    if let volumes = manga.volumes {
                        HStack(spacing: 8) {
                            Image(systemName: "book.closed.fill")
                            Text("\(volumes) vols")
                        }
                    }

                    HStack(spacing: 8) {
                        Image(systemName: manga.status == "finished" ? "checkmark.circle.fill" : "clock.fill")
                        Text(manga.status.capitalized)
                    }
                }
                .font(.title3)
                .foregroundStyle(.secondary)

                // Genres
                if !manga.genres.isEmpty {
                    HStack(spacing: 10) {
                        ForEach(manga.genres.prefix(4)) { genre in
                            Text(localizedAPIValue(genre.genre))
                                .font(.callout)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.2), in: Capsule())
                        }
                    }
                }

                // Synopsis
                if let synopsis = manga.sypnosis, !synopsis.isEmpty {
                    Text(synopsis)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .frame(maxWidth: 700, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 20)
        .hoverEffect()
        .task {
            coverVM.getImage(url: manga.coverURL)
        }
    }
}

#Preview {
    VisionHeroCarousel(mangas: [.test])
}
