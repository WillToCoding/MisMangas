//
//  VisionCollectionCard.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 18/02/26.
//

import SwiftUI

struct VisionCollectionCard: View {
    let item: UserMangaCollection
    @State private var coverVM = MangaCoverVM()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Cover
            ZStack(alignment: .topTrailing) {
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

                // Status badge
                if let total = item.manga.volumes, item.volumesOwned.count >= total {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.green, in: Circle())
                        .padding(8)
                } else if let reading = item.readingVolume, reading > 1 {
                    Image(systemName: "book.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.blue, in: Circle())
                        .padding(8)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(item.manga.title)
                    .font(.headline)
                    .lineLimit(1)
                    .frame(width: 200, alignment: .leading)

                if let total = item.manga.volumes {
                    let reading = item.readingVolume ?? 1
                    HStack {
                        Text("Vol. \(reading)/\(total)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(Int((Double(reading) / Double(total)) * 100))%")
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                    }
                    .frame(width: 200)

                    ProgressView(value: Double(reading), total: Double(total))
                        .frame(width: 200)
                        .tint(.blue)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.gray.opacity(0.15)))
        .hoverEffect()
        .task {
            coverVM.getImage(url: item.manga.coverURL)
        }
    }
}

#Preview {
    VisionCollectionCard(item: .test)
        .padding()
}
