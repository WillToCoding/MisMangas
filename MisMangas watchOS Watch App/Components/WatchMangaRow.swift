//
//  WatchMangaRow.swift
//  MisMangas watchOS Watch App
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI
import WatchKit

struct WatchMangaRow: View {
    let itemId: String
    @Bindable var cloudVM: CloudCollectionViewModel

    @State private var coverVM = MangaCoverVM()
    @State private var isIncrementing = false

    // Obtener el item actualizado de la colección
    private var currentItem: UserMangaCollection? {
        cloudVM.cloudCollection.first(where: { $0.id == itemId })
    }

    var body: some View {
        if let currentItem {
        HStack(spacing: 8) {
            // Imagen del manga
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
                                    .foregroundStyle(.gray)
                            }
                        }
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

                    Text(currentItem.manga.score.formatted(.number.precision(.fractionLength(1))))
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
            coverVM.getImage(url: currentItem.manga.coverURL)
            print("[ROW] Mostrando: \(currentItem.manga.title) - Vol. \(currentItem.readingVolume ?? 0)")
        }
        .swipeActions(edge: .trailing) {
            Button {
                Task {
                    await incrementVolume(currentItem)
                }
            } label: {
                Label("action_plus_one", systemImage: "plus")
            }
            .tint(.blue)
            .disabled(isIncrementing || !canIncrement(currentItem))
        }
        } else {
            Text("item_not_found")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Quick Actions

    private func canIncrement(_ item: UserMangaCollection) -> Bool {
        let current = item.readingVolume ?? 0
        let max = item.manga.volumes ?? 999
        return current < max
    }

    private func incrementVolume(_ item: UserMangaCollection) async {
        isIncrementing = true
        let newVolume = (item.readingVolume ?? 0) + 1

        do {
            try await cloudVM.addToCollection(
                manga: item.manga,
                volumesOwned: item.volumesOwned,
                readingVolume: newVolume,
                completeCollection: item.completeCollection
            )
            WKInterfaceDevice.current().play(.success)
        } catch {
            WKInterfaceDevice.current().play(.failure)
        }

        isIncrementing = false
    }
}

#Preview {
    let authVM = AuthViewModel()
    let cloudVM = CloudCollectionViewModel(authVM: authVM)

    List {
        WatchMangaRow(itemId: UserMangaCollection.test.id, cloudVM: cloudVM)
    }
}
