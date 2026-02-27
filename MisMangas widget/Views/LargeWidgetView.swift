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

    private let collectionURL = URL(string: "mismangas://collection")

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Stats Header
            WidgetStatsHeader(widgetData: entry.widgetData)

            if mangas.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                // Grid de mangas
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(mangas) { manga in
                        Link(destination: URL(string: "mismangas://manga/\(manga.id)")!) {
                            WidgetMangaCard(manga: manga, style: .large)
                        }
                    }
                }
            }
        }
        .padding()
        .widgetURL(collectionURL)
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

#Preview("Con datos", as: .systemLarge) {
    MisMangas_widget()
} timeline: {
    MangaWidgetEntry(date: .now, widgetData: .placeholder)
}

#Preview("Vacío", as: .systemLarge) {
    MisMangas_widget()
} timeline: {
    MangaWidgetEntry(date: .now, widgetData: .empty)
}
