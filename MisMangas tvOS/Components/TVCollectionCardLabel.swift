//
//  TVCollectionCardLabel.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct TVCollectionCardLabel<Item: CollectionItem>: View {
    let item: Item
    let loadDelay: Double

    @State private var coverVM = MangaCoverVM()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            coverImage
            infoSection
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.gray.opacity(0.15)))
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(loadDelay))
                guard let url = item.collectionCoverURL else { return }
                coverVM.getImage(url: url)
            }
        }
    }

    // MARK: - Cover Image

    private var coverImage: some View {
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
                                    .font(.system(size: 50))
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
            }
            .frame(width: 220, height: 330)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16))

            statusBadge
                .padding(12)
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.collectionTitle)
                .font(.system(size: 24, weight: .bold))
                .lineLimit(1)
                .frame(width: 220, alignment: .leading)

            if let total = item.collectionTotalVolumes {
                progressInfo(total: total)
            } else {
                publishingStatus
            }
        }
    }

    // MARK: - Progress Info

    private func progressInfo(total: Int) -> some View {
        let reading = item.collectionReadingVolume ?? 1
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Vol. \(reading)/\(total)")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int((Double(reading) / Double(total)) * 100))%")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            .frame(width: 220)

            ProgressView(value: Double(reading), total: Double(total))
                .frame(width: 220)
                .tint(.blue)
        }
    }

    // MARK: - Publishing Status

    private var publishingStatus: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
            Text("status_publishing")
        }
        .font(.system(size: 20))
        .foregroundStyle(.secondary)
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        Group {
            if let total = item.collectionTotalVolumes, item.collectionVolumesOwned.count >= total {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.green, in: Circle())
            } else if let reading = item.collectionReadingVolume, reading > 1 {
                Image(systemName: "book.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.blue, in: Circle())
            }
        }
    }
}

#Preview("Cloud Collection") {
    TVCollectionCardLabel(item: UserMangaCollection.test, loadDelay: 0)
        .padding(40)
}

#Preview("Local Collection", traits: .sampleData) {
    TVCollectionCardLabel(item: UserCollection.preview, loadDelay: 0)
        .padding(40)
}
