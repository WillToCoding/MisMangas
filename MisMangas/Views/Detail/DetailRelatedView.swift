//
//  DetailRelatedView.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI

struct DetailRelatedView: View {
    let relatedMangas: [JikanRelation]
    let relatedMangaDetails: [Int: Manga]
    let recommendations: [JikanRecommendation]
    let isLoading: Bool
    let onMangaTap: (Int) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("detail_related_mangas")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)

            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            loadingView
        } else if relatedMangas.isEmpty && recommendations.isEmpty {
            emptyView
        } else {
            VStack(alignment: .leading, spacing: 12) {
                relationsSection
                recommendationsSection
            }
        }
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .accessibilityLabel(String(localized: "accessibility_loading_related"))
            Spacer()
        }
        .padding(.vertical)
    }

    private var emptyView: some View {
        Text("detail_related_empty")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    // MARK: - Relations Section
    private var relationsSection: some View {
        ForEach(relatedMangas) { relation in
            RelationGroup(
                relation: relation,
                mangaDetails: relatedMangaDetails,
                onMangaTap: onMangaTap
            )
        }
    }

    // MARK: - Recommendations Section
    @ViewBuilder
    private var recommendationsSection: some View {
        if !recommendations.isEmpty {
            Text("detail_recommendations")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h3)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recommendations.prefix(10)) { rec in
                        RecommendationCard(
                            recommendation: rec,
                            onTap: { Task { await onMangaTap(rec.entry.malId) } }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Relation Group
private struct RelationGroup: View {
    let relation: JikanRelation
    let mangaDetails: [Int: Manga]
    let onMangaTap: (Int) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(localizedRelationType(relation.relation))
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h3)

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
private struct RelatedMangaCard: View {
    let entry: JikanRelationEntry
    let manga: Manga?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                if let manga = manga {
                    CachedCoverImage(
                        url: URL(string: manga.mainPicture.replacingOccurrences(of: "\"", with: "")),
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
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
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
private struct RecommendationCard: View {
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
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
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

// MARK: - Helper
private func localizedRelationType(_ type: String) -> String {
    switch type.lowercased() {
    case "sequel": return String(localized: "relation_sequel")
    case "prequel": return String(localized: "relation_prequel")
    case "side story": return String(localized: "relation_side_story")
    case "spin-off": return String(localized: "relation_spin_off")
    case "alternative version": return String(localized: "relation_alternative")
    case "alternative setting": return String(localized: "relation_alternative_setting")
    case "adaptation": return String(localized: "relation_adaptation")
    case "summary": return String(localized: "relation_summary")
    case "full story": return String(localized: "relation_full_story")
    case "parent story": return String(localized: "relation_parent_story")
    case "other": return String(localized: "relation_other")
    default: return type
    }
}

#Preview {
    DetailRelatedView(
        relatedMangas: [],
        relatedMangaDetails: [:],
        recommendations: [],
        isLoading: false,
        onMangaTap: { _ in }
    )
    .padding()
}
