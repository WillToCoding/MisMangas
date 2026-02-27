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

    private let collectionURL = URL(string: "mismangas://collection")

    var body: some View {
        Group {
            if mangas.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    // Stats Header
                    WidgetStatsHeader(widgetData: entry.widgetData, compact: false)

                    // Mangas
                    HStack(spacing: 12) {
                        ForEach(mangas) { manga in
                            Link(destination: URL(string: "mismangas://manga/\(manga.id)")!) {
                                WidgetMangaCard(manga: manga, style: .medium)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .widgetURL(collectionURL)
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

#Preview("Con datos", as: .systemMedium) {
    MisMangas_widget()
} timeline: {
    MangaWidgetEntry(date: .now, widgetData: .placeholder)
}

#Preview("Vacío", as: .systemMedium) {
    MisMangas_widget()
} timeline: {
    MangaWidgetEntry(date: .now, widgetData: .empty)
}
