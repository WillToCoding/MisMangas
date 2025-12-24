//
//  MangaGridView.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct MangaGridView: View {
    let mangas: [Manga]

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
                        MangaGridCell(manga: manga)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Portada
            AsyncImage(url: URL(string: manga.mainPicture.replacingOccurrences(of: "\"", with: ""))) { phase in
                switch phase {
                case .empty:
                    Color.gray.opacity(0.3)
                        .overlay {
                            ProgressView()
                        }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Color.gray.opacity(0.3)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    Color.gray.opacity(0.3)
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

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
                Text(String(format: "%.1f", manga.score))
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
        }
        .frame(width: 150)
    }
}

// MARK: - Preview
#Preview("Grid con mangas") {
    NavigationStack {
        MangaGridView(mangas: [
            .test,
            .test,
            .test,
            .test,
            .test,
            .test
        ])
    }
}

#Preview("Single Cell") {
    MangaGridCell(manga: .test)
        .padding()
}
