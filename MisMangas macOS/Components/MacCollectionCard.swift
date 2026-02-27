//
//  MacCollectionCard.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

/// Card para mostrar un manga de la colección cloud
struct MacCollectionCard: View {
    let manga: Manga
    let item: UserMangaCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                CachedCoverImage(
                    url: manga.coverURL,
                    width: 120,
                    height: 180,
                    cornerRadius: 12
                )

                progressBadge
                scoreBadge
            }

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

    // MARK: - Subviews

    private var progressBadge: some View {
        Group {
            if item.completeCollection {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                    .background(Circle().fill(.white).padding(2))
                    .padding(8)
            } else if let reading = item.readingVolume, let total = manga.volumes {
                Text("\(reading)/\(total)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.blue, in: Capsule())
                    .padding(8)
            }
        }
    }

    private var scoreBadge: some View {
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
}

#Preview {
    MacCollectionCard(manga: .test, item: .test)
        .padding()
}
