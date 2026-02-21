//
//  TVMangaCard.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct TVMangaCard: View {
    let item: UserMangaCollection
    let loadDelay: Double

    @Environment(\.isFocused) private var isFocused
    @State private var shouldLoad = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Portada
            AsyncImage(url: shouldLoad ? URL(string: item.manga.mainPicture.replacingOccurrences(of: "\"", with: "")) : nil) { phase in
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
                        .scaledToFit()
                case .failure:
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundStyle(.gray)
                        }
                @unknown default:
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                }
            }
            .frame(width: 300, height: 450)
            .background(.gray.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: isFocused ? 30 : 10)
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isFocused)

            // Info
            VStack(alignment: .leading, spacing: 12) {
                Text(item.manga.title)
                    .font(.system(size: 28, weight: .bold))
                    .lineLimit(2)
                    .frame(width: 300, height: 70, alignment: .topLeading)

                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 20))
                    Text(String(format: "%.2f", item.manga.score))
                        .font(.system(size: 24, weight: .semibold))
                }

                // Progreso - siempre ocupa el mismo espacio
                Group {
                    if let total = item.manga.volumes {
                        let reading = item.readingVolume ?? 1
                        VStack(alignment: .leading, spacing: 8) {
                            Text("vol_progress \(reading) \(total)")
                                .font(.system(size: 20))
                                .foregroundStyle(.secondary)

                            ProgressView(value: Double(reading), total: Double(total))
                                .frame(width: 300)
                                .scaleEffect(y: 2.0)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("status_publishing")
                                .font(.system(size: 20))
                                .foregroundStyle(.secondary)

                            Spacer()
                                .frame(height: 4)
                        }
                    }
                }
                .frame(height: 60)
            }
            .frame(width: 300)
        }
        .frame(width: 350)
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(loadDelay))
                shouldLoad = true
            }
        }
    }
}
