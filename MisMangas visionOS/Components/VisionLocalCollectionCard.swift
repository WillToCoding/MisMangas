//
//  VisionLocalCollectionCard.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 26/02/26.
//

import SwiftUI

struct VisionLocalCollectionCard: View {
    let item: UserCollection
    @State private var coverVM = MangaCoverVM()

    private var progress: Double {
        guard let total = item.manga.volumes, total > 0 else { return 0 }
        return Double(item.currentReadingVolume ?? 0) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
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
                                    Image(systemName: "book.closed")
                                        .font(.largeTitle)
                                        .foregroundStyle(.gray)
                                }
                            }
                    }
                }
                .frame(width: 200, height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                if item.hasCompleteCollection {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                        .background(Circle().fill(.white))
                        .padding(8)
                }
            }

            Text(item.manga.title)
                .font(.headline)
                .lineLimit(2)
                .frame(width: 200, alignment: .leading)

            if let total = item.manga.volumes {
                ProgressView(value: progress)
                    .tint(progress >= 1 ? .green : .blue)
                    .frame(width: 200)

                Text("vol_progress \(item.currentReadingVolume ?? 0)/\(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            coverVM.getImage(url: item.manga.coverURL)
        }
    }
}

#Preview {
    VisionLocalCollectionCard(item: .preview)
        .padding()
}
