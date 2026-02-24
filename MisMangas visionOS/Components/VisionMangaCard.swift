//
//  VisionMangaCard.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

/// Card genérico para mostrar mangas en visionOS.
/// Funciona tanto para exploración como para colección.
struct VisionMangaCard: View {
    let title: String
    let imageURL: String
    let score: Double
    let volumes: Int?

    /// Progreso de lectura (solo para colección)
    var readingProgress: (current: Int, total: Int)? = nil

    /// Géneros a mostrar (solo para exploración)
    var genres: [String]? = nil

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Portada con efecto 3D
            coverImage

            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(readingProgress != nil ? .title2.bold() : .title3.bold())
                    .lineLimit(2)

                scoreAndVolumes

                // Progreso (colección) o Géneros (exploración)
                if let progress = readingProgress {
                    progressView(progress)
                } else if let genres = genres, !genres.isEmpty {
                    genresView(genres)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(width: readingProgress != nil ? 300 : 280)
        .padding()
        .glassBackgroundEffect()
        .hoverEffect()
        .onHover { hovering in
            isHovered = hovering
        }
    }

    // MARK: - Subviews

    private var coverImage: some View {
        AsyncImage(url: URL(string: imageURL.replacingOccurrences(of: "\"", with: ""))) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .overlay {
                        ProgressView()
                    }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.gray)
                    }
            @unknown default:
                Rectangle()
                    .fill(.gray.opacity(0.3))
            }
        }
        .frame(
            width: readingProgress != nil ? 300 : 280,
            height: readingProgress != nil ? 450 : 420
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: isHovered ? 20 : 10)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
    }

    private var scoreAndVolumes: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
            Text(score.formatted(.number.precision(.fractionLength(2))))
                .font(.headline)

            Spacer()

            if let volumes = volumes, readingProgress == nil {
                Text("\(volumes) vols")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func progressView(_ progress: (current: Int, total: Int)) -> some View {
        HStack {
            Text("vol_progress \(progress.current) \(progress.total)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            ProgressView(value: Double(progress.current), total: Double(progress.total))
                .frame(width: 100)
        }
    }

    private func genresView(_ genres: [String]) -> some View {
        Text(genres.prefix(3).joined(separator: ", "))
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}

// MARK: - Convenience Initializers

extension VisionMangaCard {
    /// Inicializador para mangas de exploración
    init(manga: Manga) {
        self.title = manga.title
        self.imageURL = manga.mainPicture
        self.score = manga.score
        self.volumes = manga.volumes
        self.readingProgress = nil
        self.genres = manga.genres.map(\.genre)
    }

    /// Inicializador para items de colección
    init(item: UserMangaCollection) {
        self.title = item.manga.title
        self.imageURL = item.manga.mainPicture
        self.score = item.manga.score
        self.volumes = item.manga.volumes

        if let total = item.manga.volumes {
            self.readingProgress = (item.readingVolume ?? 1, total)
        } else {
            self.readingProgress = nil
        }
        self.genres = nil
    }
}

#Preview("Exploración") {
    VisionMangaCard(manga: .test)
}

#Preview("Colección") {
    VisionMangaCard(
        title: "Dragon Ball",
        imageURL: "https://cdn.myanimelist.net/images/manga/1/267793l.jpg",
        score: 8.41,
        volumes: 42,
        readingProgress: (15, 42)
    )
}
