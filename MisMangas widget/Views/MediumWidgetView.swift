//
//  MediumWidgetView.swift
//  MisMangas widget
//
//  Created by Juan Carlos on 23/12/25.
//

import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: MangaWidgetEntry

    var mangas: [WidgetManga] {
        Array(entry.widgetData.mangas.prefix(3))
    }

    var body: some View {
        if mangas.isEmpty {
            emptyState
        } else {
            HStack(spacing: 12) {
                ForEach(mangas) { manga in
                    MangaCardView(manga: manga)
                }
            }
            .padding()
        }
    }

    private var emptyState: some View {
        HStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("app_name")
                    .font(.headline)
                Text("widget_open_app")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

struct MangaCardView: View {
    let manga: WidgetManga

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Portada
            if let image = manga.localImage {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [.purple.opacity(0.6), .blue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 80)
                    .overlay {
                        Image(systemName: "book.closed")
                            .foregroundStyle(.white.opacity(0.7))
                    }
            }

            // Info
            Text(manga.title)
                .font(.caption2)
                .fontWeight(.semibold)
                .lineLimit(1)

            Text(manga.progressText)
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Progreso
            ProgressView(value: manga.progressPercentage)
                .tint(Color.accentColor)
        }
    }
}
