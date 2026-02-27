//
//  RectangularLockScreenView.swift
//  MisMangas widget
//
//  Created by Juan Carlos on 23/12/25.
//

import SwiftUI
import WidgetKit

struct RectangularLockScreenView: View {
    let entry: MangaWidgetEntry

    var manga: WidgetManga? {
        entry.widgetData.mangas.first
    }

    private let collectionURL = URL(string: "mismangas://collection")

    private var deepLinkURL: URL? {
        if let manga = manga {
            return URL(string: "mismangas://manga/\(manga.id)")
        }
        return collectionURL
    }

    var body: some View {
        Group {
            if let manga = manga {
                HStack(spacing: 8) {
                    // Portada o icono
                    if let image = manga.localImage {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 30, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Image(systemName: "book.fill")
                            .font(.title3)
                    }

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
        .widgetURL(deepLinkURL)
    }
}

#Preview("Rectangular", as: .accessoryRectangular) {
    MisMangas_widget()
} timeline: {
    MangaWidgetEntry(date: .now, widgetData: .placeholder)
}
