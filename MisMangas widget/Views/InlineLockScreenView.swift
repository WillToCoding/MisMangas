//
//  InlineLockScreenView.swift
//  MisMangas widget
//
//  Created by Juan Carlos on 23/12/25.
//

import SwiftUI
import WidgetKit

struct InlineLockScreenView: View {
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
                Text("\(manga.title) - \(manga.progressText)")
            } else {
                Text("app_name")
            }
        }
        .widgetURL(deepLinkURL)
    }
}

#Preview("Inline", as: .accessoryInline) {
    MisMangas_widget()
} timeline: {
    MangaWidgetEntry(date: .now, widgetData: .placeholder)
}
