//
//  DetailRelatedView+Components.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI

// MARK: - Relation Group

struct RelationGroup: View {
    let relation: JikanRelation
    let mangaDetails: [Int: Manga]
    let onMangaTap: (Int) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(localizedRelationType(relation.relation))
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHeader(.h3)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(relation.entry.filter { $0.type == "manga" }) { entry in
                        RelatedMangaCard(
                            entry: entry,
                            manga: mangaDetails[entry.malId],
                            onTap: { Task { await onMangaTap(entry.malId) } }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Related Manga Card

struct RelatedMangaCard: View {
    let entry: JikanRelationEntry
    let manga: Manga?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                if let manga = manga {
                    CachedCoverImage(
                        url: manga.coverURL,
                        width: 60,
                        height: 80
                    )
                    .accessibilityHidden(true)
                } else {
                    // Placeholder mientras carga
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 80)
                        .overlay {
                            ProgressView()
                        }
                        .accessibilityHidden(true)
                }

                Text(entry.name)
                    .font(.caption2)
                    .lineLimit(1)
                    .frame(width: 60)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(entry.name)
        .accessibilityHint(String(localized: "accessibility_double_tap_details"))
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let recommendation: JikanRecommendation
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                CachedCoverImage(
                    url: URL(string: recommendation.entry.images.jpg.imageUrl),
                    width: 60,
                    height: 80
                )
                .accessibilityHidden(true)

                Text(recommendation.entry.title)
                    .font(.caption2)
                    .lineLimit(1)
                    .frame(width: 60)
                    .foregroundStyle(.primary)

                HStack(spacing: 2) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.caption2)
                    Text("\(recommendation.votes)")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(recommendation.entry.title), \(recommendation.votes) " + String(localized: "accessibility_votes"))
        .accessibilityHint(String(localized: "accessibility_double_tap_details"))
    }
}
