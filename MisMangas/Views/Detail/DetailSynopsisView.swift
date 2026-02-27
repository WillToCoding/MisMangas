//
//  DetailSynopsisView.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI

struct DetailSynopsisView: View {
    let synopsis: String?
    let background: String?
    let translatedSynopsis: String?
    let translatedBackground: String?
    let isTranslating: Bool
    let showOriginal: Bool
    let canTranslate: Bool
    let onToggleTranslation: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let synopsis {
                synopsisSection(synopsis)
            }

            if let background {
                backgroundSection(background)
            }
        }
    }

    // MARK: - Synopsis Section
    private func synopsisSection(_ synopsis: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("detail_synopsis", systemImage: "text.alignleft")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .accessibilityHeader(.h2)

                Spacer()

                translationButton
            }

            Text(showOriginal ? synopsis : (translatedSynopsis ?? synopsis))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Background Section
    private func backgroundSection(_ background: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("detail_background", systemImage: "info.circle.fill")
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
                .accessibilityHeader(.h2)

            Text(showOriginal ? background : (translatedBackground ?? background))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Translation Button
    private var translationButton: some View {
        Group {
            if canTranslate {
                if isTranslating {
                    ProgressView()
                        .scaleEffect(0.7)
                } else if translatedSynopsis != nil {
                    Button(action: onToggleTranslation) {
                        Image(systemName: showOriginal ? "globe" : "text.bubble")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(showOriginal ? String(localized: "translation_show_translated") : String(localized: "translation_show_original"))
                }
            }
        }
    }
}

// MARK: - Dates Section
struct DetailDatesView: View {
    let startDate: String?
    let endDate: String?

    var body: some View {
        HStack(spacing: 16) {
            if let startDate {
                dateItem(
                    icon: "calendar.badge.plus",
                    label: "detail_start_date",
                    date: startDate,
                    color: .green,
                    accessibilityLabel: "accessibility_start_date"
                )
            }

            if let endDate {
                dateItem(
                    icon: "calendar.badge.checkmark",
                    label: "detail_end_date",
                    date: endDate,
                    color: .blue,
                    accessibilityLabel: "accessibility_end_date"
                )
            }

            Spacer()
        }
    }

    private func dateItem(icon: String, label: LocalizedStringKey, date: String, color: Color, accessibilityLabel: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(formatDate(date))
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: String.LocalizationValue(accessibilityLabel)) + ": " + formatDate(date))
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

#Preview("Synopsis") {
    DetailSynopsisView(
        synopsis: Manga.test.sypnosis,
        background: Manga.test.background,
        translatedSynopsis: nil,
        translatedBackground: nil,
        isTranslating: false,
        showOriginal: false,
        canTranslate: true,
        onToggleTranslation: {}
    )
    .padding()
}

#Preview("Dates") {
    DetailDatesView(
        startDate: Manga.test.startDate,
        endDate: Manga.test.endDate
    )
    .padding()
}
