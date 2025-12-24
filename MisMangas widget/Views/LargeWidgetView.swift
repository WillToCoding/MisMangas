//
//  LargeWidgetView.swift
//  MisMangas widget
//
//  Created by Juan Carlos on 23/12/25.
//

import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let entry: MangaWidgetEntry

    var mangas: [WidgetManga] {
        Array(entry.widgetData.mangas.prefix(6))
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "books.vertical.fill")
                    .foregroundStyle(Color.accentColor)
                Text("widget_reading_now")
                    .font(.headline)
                Spacer()
                if let email = entry.widgetData.userEmail {
                    Text(email)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if mangas.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                // Grid de mangas
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(mangas) { manga in
                        LargeMangaCard(manga: manga)
                    }
                }
            }
        }
        .padding()
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("widget_no_reading")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("collection_empty_description")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LargeMangaCard: View {
    let manga: WidgetManga

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Portada
            if let image = manga.localImage {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [.purple.opacity(0.6), .blue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 90)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.white.opacity(0.7))
                    }
            }

            // Título
            Text(manga.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            // Progreso
            HStack(spacing: 4) {
                Image(systemName: "book.fill")
                    .font(.system(size: 8))
                Text(manga.progressText)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)

            ProgressView(value: manga.progressPercentage)
                .tint(Color.accentColor)
        }
    }
}
