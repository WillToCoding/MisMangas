//
//  MangaRow.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI

struct MangaRow: View {
    let manga: Manga

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: manga.mainPicture.replacingOccurrences(of: "\"", with: ""))) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))

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

                    if let volumes = manga.volumes {
                        Text("separator_dot")
                            .foregroundStyle(.secondary)

                        Text("stats_vols \(volumes)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !manga.genres.isEmpty {
                    Text(manga.genres.prefix(3).map(\.genre).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MangaRow(manga: .test)
}
