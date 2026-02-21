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
        VStack(alignment: .leading, spacing: 16) {
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("detail_synopsis")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h2)

                Spacer()

                translationButton
            }

            Text(showOriginal ? synopsis : (translatedSynopsis ?? synopsis))
                .font(.body)
                .lineSpacing(4)
        }
    }

    // MARK: - Background Section
    private func backgroundSection(_ background: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("detail_background")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)

            Text(showOriginal ? background : (translatedBackground ?? background))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
    }

    // MARK: - Translation Button
    @ViewBuilder
    private var translationButton: some View {
        if canTranslate {
            if isTranslating {
                ProgressView()
                    .scaleEffect(0.8)
            } else if translatedSynopsis != nil {
                Button(action: onToggleTranslation) {
                    Label(
                        showOriginal ? "translation_show_translated" : "translation_show_original",
                        systemImage: "globe"
                    )
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
}

// MARK: - Dates Section
struct DetailDatesView: View {
    let startDate: String?
    let endDate: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let startDate {
                dateRow(label: "detail_start_date", date: startDate, accessibilityLabel: "accessibility_start_date")
            }

            if let endDate {
                dateRow(label: "detail_end_date", date: endDate, accessibilityLabel: "accessibility_end_date")
            }
        }
    }

    private func dateRow(label: LocalizedStringKey, date: String, accessibilityLabel: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(formatDate(date))
                .font(.caption)
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

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            DetailSynopsisView(
                synopsis: "This is a sample synopsis for the manga. It contains information about the story.",
                background: "This manga was created in 1997 and became very popular.",
                translatedSynopsis: nil,
                translatedBackground: nil,
                isTranslating: false,
                showOriginal: false,
                canTranslate: true,
                onToggleTranslation: {}
            )

            Divider()

            DetailDatesView(
                startDate: "1997-07-22T00:00:00Z",
                endDate: "2025-01-01T00:00:00Z"
            )
        }
        .padding()
    }
}
