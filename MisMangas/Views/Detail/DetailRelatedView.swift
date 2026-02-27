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
                .accessibilityHeader(.h2)

            content
        }
    }

    private var content: some View {
        Group {
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

    private var recommendationsSection: some View {
        Group {
            if !recommendations.isEmpty {
                Text("detail_recommendations")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                    .accessibilityHeader(.h3)

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
