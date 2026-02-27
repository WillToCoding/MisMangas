//
//  MacMangaDetailView+Related.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 26/2/26.
//

import SwiftUI

// MARK: - Related Mangas Section

extension MacMangaDetailView {
    var relatedMangasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("detail_related_mangas")
                .font(.title2.bold())

            if viewModel.isLoadingRelated {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical)
            } else if viewModel.relatedMangas.isEmpty && viewModel.recommendations.isEmpty {
                Text("detail_related_empty")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                relatedMangasList
                recommendationsList
            }
        }
    }

    private var relatedMangasList: some View {
        ForEach(viewModel.relatedMangas) { relation in
            VStack(alignment: .leading, spacing: 8) {
                Text(localizedRelationType(relation.relation))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal) {
                    HStack(spacing: 16) {
                        ForEach(relation.entry.filter { $0.type == "manga" }) { entry in
                            relatedMangaButton(entry: entry)
                        }
                    }
                }
            }
        }
    }

    private func relatedMangaButton(entry: JikanRelationEntry) -> some View {
        Button {
            Task { await viewModel.loadAndNavigateToManga(id: entry.malId) }
        } label: {
            VStack(spacing: 6) {
                if let mangaDetail = viewModel.relatedMangaDetails[entry.malId] {
                    CachedCoverImage(url: mangaDetail.coverURL, width: 80, height: 110)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 110)
                        .overlay { ProgressView() }
                }

                Text(entry.name)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }

    private var recommendationsList: some View {
        Group {
            if !viewModel.recommendations.isEmpty {
                Text("detail_recommendations")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 12)

                ScrollView(.horizontal) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.recommendations.prefix(10)) { rec in
                            recommendationButton(rec: rec)
                        }
                    }
                }
            }
        }
    }

    private func recommendationButton(rec: JikanRecommendation) -> some View {
        Button {
            Task { await viewModel.loadAndNavigateToManga(id: rec.entry.malId) }
        } label: {
            VStack(spacing: 6) {
                CachedCoverImage(
                    url: URL(string: rec.entry.images.jpg.imageUrl),
                    width: 80,
                    height: 110
                )

                Text(rec.entry.title)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.system(size: 10))
                    Text("\(rec.votes)")
                        .font(.system(size: 10))
                }
                .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
