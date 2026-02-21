//
//  DetailHeaderView.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI
import SwiftData

struct DetailHeaderView: View {
    let manga: Manga
    let namespace: Namespace.ID
    var userCollection: UserCollection?

    private var coverURL: URL? {
        URL(string: manga.mainPicture.replacingOccurrences(of: "\"", with: ""))
    }

    var body: some View {
        VStack(spacing: 20) {
            // Portada con caché y animación hero
            MangaCoverDetailView(url: coverURL, namespace: namespace, size: .large)
                .accessibilityLabel(String(localized: "accessibility_cover \(manga.title)"))

            // Títulos - centrados
            VStack(spacing: 6) {
                Text(manga.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h1)

                if let englishTitle = manga.titleEnglish, englishTitle != manga.title {
                    Text(englishTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .accessibilityLabel(String(localized: "accessibility_english_title \(englishTitle)"))
                }

                if let japaneseTitle = manga.titleJapanese {
                    Text(japaneseTitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .accessibilityLabel(String(localized: "accessibility_japanese_title \(japaneseTitle)"))
                }
            }

            // Stats de la API (siempre visibles)
            DetailStatsView(manga: manga)

            // Stats del usuario (desde SwiftData local)
            if let collection = userCollection {
                UserStatsView(manga: manga, collection: collection)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stats
struct DetailStatsView: View {
    let manga: Manga

    private var isFinished: Bool {
        manga.status == "finished"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Score
            StatCard(
                value: String(format: "%.2f", manga.score),
                label: "detail_score",
                icon: "star.fill",
                color: .orange
            )
            .accessibilityLabel(String(localized: "accessibility_score \(String(format: "%.1f", manga.score))"))

            // Volumes (siempre visible)
            StatCard(
                value: manga.volumes.map { "\($0)" } ?? "?",
                label: "detail_volumes",
                icon: "books.vertical",
                color: .blue
            )
            .accessibilityLabel("\(manga.volumes ?? 0) " + String(localized: "accessibility_volumes"))

            // Chapters (siempre visible)
            StatCard(
                value: manga.chapters.map { "\($0)" } ?? "?",
                label: "detail_chapters",
                icon: "book.pages",
                color: .purple
            )
            .accessibilityLabel("\(manga.chapters ?? 0) " + String(localized: "accessibility_chapters"))

            // Status
            StatCard(
                value: isFinished ? String(localized: "status_finished") : String(localized: "status_publishing"),
                label: "detail_status",
                icon: isFinished ? "checkmark.circle.fill" : "clock.fill",
                color: isFinished ? .green : .blue
            )
            .accessibilityLabel(String(localized: "accessibility_status") + ": " + (isFinished ? String(localized: "status_finished") : String(localized: "status_publishing")))
        }
    }
}

// MARK: - Stat Card
private struct StatCard: View {
    let value: String
    let label: LocalizedStringKey
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("Sin colección") {
    @Previewable @Namespace var namespace
    ScrollView {
        DetailHeaderView(manga: .test, namespace: namespace)
            .padding()
    }
}

#Preview("En colección", traits: .sampleData) {
    @Previewable @Namespace var namespace
    ScrollView {
        DetailHeaderView(manga: .test, namespace: namespace, userCollection: PreviewData.shared.allCollections.first)
            .padding()
    }
}
