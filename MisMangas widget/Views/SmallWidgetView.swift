//
//  SmallWidgetView.swift
//  MisMangas widget
//
//  Created by Juan Carlos on 23/12/25.
//

import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: MangaWidgetEntry

    var manga: WidgetManga? {
        entry.widgetData.mangas.first
    }

    var body: some View {
        if let manga = manga {
            ZStack {
                // Fondo con imagen local o gradiente
                if let image = manga.localImage {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }

                // Overlay oscuro
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Contenido
                VStack(alignment: .leading) {
                    Spacer()

                    Text(manga.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .shadow(radius: 2)

                    HStack {
                        Image(systemName: "book.fill")
                            .font(.caption)
                        Text(manga.progressText)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white.opacity(0.9))

                    // Barra de progreso
                    ProgressView(value: manga.progressPercentage)
                        .tint(.white)
                        .background(.white.opacity(0.3))
                }
                .padding()
            }
        } else {
            // Estado vacío
            VStack(spacing: 8) {
                Image(systemName: "books.vertical")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("collection_empty_title")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("collection_empty_description")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}
