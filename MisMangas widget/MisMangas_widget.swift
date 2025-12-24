//
//  MisMangas_widget.swift
//  MisMangas widget
//
//  Created by Juan Carlos on 23/12/25.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct MangaWidgetEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetData
}

// MARK: - Timeline Provider

struct MangaWidgetProvider: TimelineProvider {
    typealias Entry = MangaWidgetEntry

    private static let appGroupID = "group.com.murtidev.MisMangas"
    private static let widgetDataKey = "widgetMangaData"

    // MARK: - Load from App Group

    private static func loadFromAppGroup() -> WidgetData {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: widgetDataKey),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return .empty
        }
        return decoded
    }

    // MARK: - TimelineProvider

    func placeholder(in context: Context) -> MangaWidgetEntry {
        MangaWidgetEntry(date: Date(), widgetData: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (MangaWidgetEntry) -> Void) {
        let widgetData = Self.loadFromAppGroup()
        let entry = MangaWidgetEntry(
            date: Date(),
            widgetData: widgetData.mangas.isEmpty ? .placeholder : widgetData
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MangaWidgetEntry>) -> Void) {
        let widgetData = Self.loadFromAppGroup()
        let entry = MangaWidgetEntry(date: Date(), widgetData: widgetData)

        // Actualizar cada 30 minutos
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Home Screen Widget

struct MisMangas_widget: Widget {
    let kind: String = "MisMangas_widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MangaWidgetProvider()) { entry in
            MisMangasWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("app_name")
        .description("widget_description")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

struct MisMangasWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: MangaWidgetEntry

    var body: some View {
        switch family {
        // Home Screen
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        // Lock Screen
        case .accessoryCircular:
            CircularLockScreenView(entry: entry)
        case .accessoryRectangular:
            RectangularLockScreenView(entry: entry)
        case .accessoryInline:
            InlineLockScreenView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

