//
//  LockScreenWidgetView.swift
//  MisMangas widget
//
//  Created by Juan Carlos on 23/12/25.
//

import SwiftUI
import WidgetKit

// MARK: - Rectangular Lock Screen Widget

struct RectangularLockScreenView: View {
    let entry: MangaWidgetEntry

    var manga: WidgetManga? {
        entry.widgetData.mangas.first
    }

    var body: some View {
        if let manga = manga {
            HStack(spacing: 8) {
                // Icono
                Image(systemName: "book.fill")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(manga.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(manga.progressText)
                        .font(.caption2)

                    ProgressView(value: manga.progressPercentage)
                }
            }
        } else {
            HStack {
                Image(systemName: "books.vertical")
                Text("widget_no_reading")
                    .font(.caption)
            }
        }
    }
}

// MARK: - Circular Lock Screen Widget

struct CircularLockScreenView: View {
    let entry: MangaWidgetEntry

    var mangaCount: Int {
        entry.widgetData.mangas.count
    }

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text("\(mangaCount)")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                Image(systemName: "books.vertical.fill")
                    .font(.caption2)
            }
        }
    }
}

// MARK: - Inline Lock Screen Widget

struct InlineLockScreenView: View {
    let entry: MangaWidgetEntry

    var manga: WidgetManga? {
        entry.widgetData.mangas.first
    }

    var body: some View {
        if let manga = manga {
            Text("\(manga.title) - \(manga.progressText)")
        } else {
            Text("app_name")
        }
    }
}
