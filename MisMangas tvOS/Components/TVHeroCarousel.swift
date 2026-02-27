//
//  TVHeroCarousel.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 25/2/26.
//

import SwiftUI

// MARK: - Hero Carousel

struct TVHeroCarousel: View {
    let mangas: [Manga]
    @State private var selectedIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Label("section_best_rated", systemImage: "trophy.fill")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(.yellow)
                .padding(.horizontal, 80)

            TabView(selection: $selectedIndex) {
                ForEach(Array(mangas.enumerated()), id: \.element.id) { index, manga in
                    NavigationLink(value: manga) {
                        TVHeroCard(manga: manga, rank: index + 1)
                    }
                    .buttonStyle(.card)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 500)
            .focusSection()
        }
    }
}

// MARK: - Hero Card (Carousel)

struct TVHeroCard: View {
    let manga: Manga
    var rank: Int = 0

    @State private var coverVM = MangaCoverVM()

    var body: some View {
        HStack(spacing: 60) {
            // Portada grande
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
                                    .font(.system(size: 80))
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
            }
            .frame(width: 320, height: 450)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 30)

            // Info
            VStack(alignment: .leading, spacing: 24) {
                // Rank badge
                if rank > 0 {
                    Text("#\(rank)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.yellow.gradient, in: Capsule())
                }

                Text(manga.title)
                    .font(.system(size: 48, weight: .bold))
                    .lineLimit(1)

                if let titleJapanese = manga.titleJapanese {
                    Text(titleJapanese)
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 30) {
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
                .font(.system(size: 28))
                .foregroundStyle(.secondary)

                // Géneros
                if !manga.genres.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(manga.genres.prefix(4)) { genre in
                            Text(genre.genre)
                                .font(.system(size: 22))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.blue.opacity(0.2), in: Capsule())
                        }
                    }
                }

                // Sinopsis corta
                if let synopsis = manga.sypnosis, !synopsis.isEmpty {
                    Text(synopsis)
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .frame(maxWidth: 800, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 80)
        .padding(.vertical, 20)
        .task {
            coverVM.getImage(url: manga.coverURL)
        }
    }
}

#Preview("Hero Carousel") {
    NavigationStack {
        TVHeroCarousel(mangas: [.test])
    }
}

#Preview("Hero Card") {
    TVHeroCard(manga: .test, rank: 1)
        .padding(40)
}
