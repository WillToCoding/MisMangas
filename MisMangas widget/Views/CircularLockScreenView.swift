//
//  CircularLockScreenView.swift
//  MisMangas widget
//
//  Created by Juan Carlos on 23/12/25.
//

import SwiftUI
import WidgetKit

struct CircularLockScreenView: View {
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
                Gauge(value: manga.progressPercentage) {
                    if let image = manga.localImage {
                        image
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "book.fill")
                    }
                } currentValueLabel: {
                    Text("\(manga.currentVolume)")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.bold)
                }
                .gaugeStyle(.accessoryCircular)
            } else {
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: "books.vertical.fill")
                        .font(.title3)
                }
            }
        }
        .widgetURL(deepLinkURL)
    }
}

#Preview("Circular", as: .accessoryCircular) {
    MisMangas_widget()
} timeline: {
    MangaWidgetEntry(date: .now, widgetData: .placeholder)
}
