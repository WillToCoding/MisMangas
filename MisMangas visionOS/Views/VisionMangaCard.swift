//
//  VisionMangaCard.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct VisionMangaCard: View {
    let itemId: String
    @Bindable var cloudVM: CloudCollectionViewModel

    @State private var isHovered = false

    // Obtener el item actualizado de la colección
    private var currentItem: UserMangaCollection? {
        let found = cloudVM.cloudCollection.first(where: { $0.id == itemId })
        if let item = found {
            print("[CARD] Item \(item.manga.title) - Vol: \(item.readingVolume ?? 0)")
        }
        return found
    }

    var body: some View {
        if let item = currentItem {
        VStack(alignment: .leading, spacing: 16) {
            // Portada con efecto 3D
            AsyncImage(url: URL(string: item.manga.mainPicture.replacingOccurrences(of: "\"", with: ""))) { phase in
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
                                .font(.largeTitle)
                                .foregroundStyle(.gray)
                        }
                @unknown default:
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                }
            }
            .frame(width: 300, height: 450)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: isHovered ? 20 : 10)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isHovered)

            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(item.manga.title)
                    .font(.title2.bold())
                    .lineLimit(2)

                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.2f", item.manga.score))
                        .font(.headline)
                }

                // Progreso
                if let total = item.manga.volumes {
                    let reading = item.readingVolume ?? 1
                    HStack {
                        Text("vol_progress \(reading) \(total)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        ProgressView(value: Double(reading), total: Double(total))
                            .frame(width: 100)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(width: 300)
        .padding()
        .glassBackgroundEffect()
        .hoverEffect()
        .onHover { hovering in
            isHovered = hovering
        }
        } else {
            // Fallback si el item no se encuentra
            VStack {
                Text("loading_generic")
                    .foregroundStyle(.secondary)
            }
            .frame(width: 300, height: 500)
        }
    }
}
