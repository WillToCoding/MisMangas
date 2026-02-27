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

    private let collectionURL = URL(string: "mismangas://collection")

    var body: some View {
        Group {
            if let manga = manga {
                VStack(alignment: .leading, spacing: 8) {
                    // Stats Header compacto → toca aquí va a Colección
                    WidgetStatsHeader(widgetData: entry.widgetData, compact: true)

                    // Manga card → toca aquí va al detalle
                    Link(destination: URL(string: "mismangas://manga/\(manga.id)")!) {
                        WidgetMangaCard(manga: manga, style: .small)
                    }
                }
                .padding()
            } else {
                emptyState
            }
        }
        .widgetURL(collectionURL)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "books.vertical")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("collection_empty_title")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview("Con datos", as: .systemSmall) {
    MisMangas_widget()
} timeline: {
    MangaWidgetEntry(date: .now, widgetData: .placeholder)
}

#Preview("Vacío", as: .systemSmall) {
    MisMangas_widget()
} timeline: {
    MangaWidgetEntry(date: .now, widgetData: .empty)
}
