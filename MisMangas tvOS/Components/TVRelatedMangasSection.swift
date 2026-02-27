//
//  TVRelatedMangasSection.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 25/2/26.
//

import SwiftUI

// MARK: - TV Related Mangas Section

struct TVRelatedMangasSection: View {
    let relatedMangas: [JikanRelation]
    let relatedMangaDetails: [Int: Manga]
    let recommendations: [JikanRecommendation]
    let isLoading: Bool
    let onMangaTap: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            Label("detail_related_mangas", systemImage: "link")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.purple)

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if relatedMangas.isEmpty && recommendations.isEmpty {
                Text("detail_related_empty")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            } else {
                // Relations (Sequel, Prequel, etc.)
                ForEach(relatedMangas) { relation in
                    TVRelationGroup(
                        relation: relation,
                        mangaDetails: relatedMangaDetails,
                        onMangaTap: onMangaTap
                    )
                }

                // Recommendations
                if !recommendations.isEmpty {
                    TVRecommendationsGroup(
                        recommendations: recommendations,
                        onMangaTap: onMangaTap
                    )
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - TV Relation Group

struct TVRelationGroup: View {
    let relation: JikanRelation
    let mangaDetails: [Int: Manga]
    let onMangaTap: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(localizedRelationType(relation.relation))
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    ForEach(relation.entry.filter { $0.type == "manga" }) { entry in
                        if let manga = mangaDetails[entry.malId] {
                            NavigationLink(value: manga) {
                                TVRelatedMangaCard(
                                    title: entry.name,
                                    coverURL: manga.coverURL
                                )
                            }
                            .buttonStyle(.card)
                        } else {
                            Button {
                                onMangaTap(entry.malId)
                            } label: {
                                TVRelatedMangaCard(
                                    title: entry.name,
                                    coverURL: nil
                                )
                            }
                            .buttonStyle(.card)
                        }
                    }
                }
            }
            .focusSection()
        }
    }
}

// MARK: - TV Recommendations Group

struct TVRecommendationsGroup: View {
    let recommendations: [JikanRecommendation]
    let onMangaTap: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("detail_recommendations")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    ForEach(recommendations.prefix(10)) { rec in
                        Button {
                            onMangaTap(rec.entry.malId)
                        } label: {
                            TVRecommendationCard(recommendation: rec)
                        }
                        .buttonStyle(.card)
                    }
                }
            }
            .focusSection()
        }
    }
}

// MARK: - TV Related Manga Card

struct TVRelatedMangaCard: View {
    let title: String
    let coverURL: URL?

    @State private var coverVM = MangaCoverVM()

    var body: some View {
        VStack(spacing: 16) {
            Group {
                if let image = coverVM.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .overlay {
                            if coverVM.isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "book.closed")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
            }
            .frame(width: 200, height: 300)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(title)
                .font(.system(size: 24, weight: .medium))
                .lineLimit(1)
                .frame(width: 200)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.gray.opacity(0.15)))
        .task {
            if let url = coverURL {
                coverVM.getImage(url: url)
            }
        }
    }
}

// MARK: - TV Recommendation Card

struct TVRecommendationCard: View {
    let recommendation: JikanRecommendation

    @State private var coverVM = MangaCoverVM()

    var body: some View {
        VStack(spacing: 16) {
            Group {
                if let image = coverVM.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .overlay {
                            if coverVM.isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
            }
            .frame(width: 200, height: 300)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 8) {
                Text(recommendation.entry.title)
                    .font(.system(size: 24, weight: .medium))
                    .lineLimit(1)
                    .frame(width: 200)

                HStack(spacing: 6) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.system(size: 20))
                    Text("\(recommendation.votes)")
                        .font(.system(size: 20))
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.gray.opacity(0.15)))
        .task {
            if let url = URL(string: recommendation.entry.images.jpg.imageUrl) {
                coverVM.getImage(url: url)
            }
        }
    }
}

#Preview("Related Section - Loading") {
    TVRelatedMangasSection(
        relatedMangas: [],
        relatedMangaDetails: [:],
        recommendations: [],
        isLoading: true,
        onMangaTap: { _ in }
    )
    .padding(40)
}

#Preview("Related Section - Empty") {
    TVRelatedMangasSection(
        relatedMangas: [],
        relatedMangaDetails: [:],
        recommendations: [],
        isLoading: false,
        onMangaTap: { _ in }
    )
    .padding(40)
}

#Preview("Related Manga Card") {
    TVRelatedMangaCard(title: "Test Manga", coverURL: nil)
        .padding(40)
}
