//
//  VisionRankedCard.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 18/02/26.
//

import SwiftUI

struct VisionRankedCard: View {
    let manga: Manga
    let rank: Int
    @State private var coverVM = MangaCoverVM()

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 16) {
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
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                }
                            }
                    }
                }
                .frame(width: 200, height: 300)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(manga.title)
                        .font(.headline)
                        .lineLimit(1)
                        .frame(width: 200, alignment: .leading)

                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text(manga.score.formatted(.number.precision(.fractionLength(1))))
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20).fill(.gray.opacity(0.15)))

            // Rank badge
            Text("#\(rank)")
                .font(.headline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.yellow.gradient, in: Capsule())
                .padding(8)
        }
        .hoverEffect()
        .task {
            coverVM.getImage(url: manga.coverURL)
        }
    }
}

#Preview {
    VisionRankedCard(manga: .test, rank: 1)
}
