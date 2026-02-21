//
//  MacMangaRow.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct MacMangaRow: View {
    let manga: Manga

    var body: some View {
        HStack(spacing: 12) {
            // Miniatura
            CachedCoverImage(
                url: URL(string: manga.mainPicture.replacingOccurrences(of: "\"", with: "")),
                width: 40,
                height: 60
            )

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(manga.title)
                    .font(.headline)
                    .lineLimit(1)

                if let english = manga.titleEnglish {
                    Text(english)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption2)

                    Text(String(format: "%.2f", manga.score))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let volumes = manga.volumes {
                        Text("separator_dot")
                            .foregroundStyle(.secondary)
                        Text("stats_vols \(volumes)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MacMangaRow(manga: .test)
}
