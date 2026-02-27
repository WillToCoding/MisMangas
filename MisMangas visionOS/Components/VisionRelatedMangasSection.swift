//
//  VisionRelatedMangasSection.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 26/02/26.
//

import SwiftUI

// MARK: - Vision Related Mangas Section

struct VisionRelatedMangasSection: View {
    let relatedMangas: [JikanRelation]
    let relatedMangaDetails: [Int: Manga]
    let recommendations: [JikanRecommendation]
    let isLoading: Bool
    let onMangaTap: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Label("detail_related_mangas", systemImage: "link")
                .font(.title2.bold())
                .foregroundStyle(.purple)

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 30)
            } else if relatedMangas.isEmpty && recommendations.isEmpty {
                Text("detail_related_empty")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                // Relations (Sequel, Prequel, etc.)
                ForEach(relatedMangas) { relation in
                    VisionRelationGroup(
                        relation: relation,
                        mangaDetails: relatedMangaDetails,
                        onMangaTap: onMangaTap
                    )
                }

                // Recommendations
                if !recommendations.isEmpty {
                    VisionRecommendationsGroup(
                        recommendations: recommendations,
                        onMangaTap: onMangaTap
                    )
                }
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Vision Relation Group

struct VisionRelationGroup: View {
    let relation: JikanRelation
    let mangaDetails: [Int: Manga]
    let onMangaTap: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizedRelationType(relation.relation))
                .font(.headline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(relation.entry.filter { $0.type == "manga" }) { entry in
                        if let manga = mangaDetails[entry.malId] {
                            NavigationLink(value: manga) {
                                VisionRelatedMangaCard(
                                    title: entry.name,
                                    coverURL: manga.coverURL
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                onMangaTap(entry.malId)
                            } label: {
                                VisionRelatedMangaCard(
                                    title: entry.name,
                                    coverURL: nil
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Vision Recommendations Group

struct VisionRecommendationsGroup: View {
    let recommendations: [JikanRecommendation]
    let onMangaTap: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("detail_recommendations")
                .font(.headline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(recommendations.prefix(10)) { rec in
                        Button {
                            onMangaTap(rec.entry.malId)
                        } label: {
                            VisionRecommendationCard(recommendation: rec)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Vision Related Manga Card

struct VisionRelatedMangaCard: View {
    let title: String
    let coverURL: URL?

    @State private var coverVM = MangaCoverVM()

    var body: some View {
        VStack(spacing: 12) {
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
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
            }
            .frame(width: 140, height: 210)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(title)
                .font(.subheadline)
                .lineLimit(1)
                .frame(width: 140)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(.gray.opacity(0.15)))
        .hoverEffect()
        .task {
            if let url = coverURL {
                coverVM.getImage(url: url)
            }
        }
    }
}

// MARK: - Vision Recommendation Card

struct VisionRecommendationCard: View {
    let recommendation: JikanRecommendation

    @State private var coverVM = MangaCoverVM()

    var body: some View {
        VStack(spacing: 12) {
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
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
            }
            .frame(width: 140, height: 210)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 6) {
                Text(recommendation.entry.title)
                    .font(.subheadline)
                    .lineLimit(1)
                    .frame(width: 140)

                HStack(spacing: 4) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.caption)
                    Text("\(recommendation.votes)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(.gray.opacity(0.15)))
        .hoverEffect()
        .task {
            if let url = URL(string: recommendation.entry.images.jpg.imageUrl) {
                coverVM.getImage(url: url)
            }
        }
    }
}

#Preview("Loading") {
    VisionRelatedMangasSection(
        relatedMangas: [],
        relatedMangaDetails: [:],
        recommendations: [],
        isLoading: true,
        onMangaTap: { _ in }
    )
    .padding()
}

#Preview("Empty") {
    VisionRelatedMangasSection(
        relatedMangas: [],
        relatedMangaDetails: [:],
        recommendations: [],
        isLoading: false,
        onMangaTap: { _ in }
    )
    .padding()
}
