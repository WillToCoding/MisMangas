//
//  WatchMangaRow.swift
//  MisMangas watchOS Watch App
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct WatchMangaRow: View {
    let itemId: String
    @Bindable var cloudVM: CloudCollectionViewModel

    // Obtener el item actualizado de la colección
    private var currentItem: UserMangaCollection? {
        cloudVM.cloudCollection.first(where: { $0.id == itemId })
    }

    var body: some View {
        if let currentItem {
        HStack(spacing: 8) {
            // Imagen del manga
            AsyncImage(url: URL(string: currentItem.manga.mainPicture.replacingOccurrences(of: "\"", with: ""))) { phase in
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
                                .foregroundStyle(.gray)
                        }
                @unknown default:
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                }
            }
            .frame(width: 40, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Información del manga
            VStack(alignment: .leading, spacing: 4) {
                Text(currentItem.manga.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption2)

                    Text(String(format: "%.1f", currentItem.manga.score))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Progress - USAR CURRENT ITEM
                if let reading = currentItem.readingVolume, let total = currentItem.manga.volumes {
                    HStack(spacing: 4) {
                        Text("vol_progress \(reading) \(total)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Spacer()

                        ProgressView(value: Double(reading), total: Double(total))
                            .frame(width: 40)
                    }
                } else {
                    Text("no_progress")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            print("[ROW] Mostrando: \(currentItem.manga.title) - Vol. \(currentItem.readingVolume ?? 0)")
        }
        } else {
            Text("item_not_found")
                .foregroundStyle(.secondary)
        }
    }
}
