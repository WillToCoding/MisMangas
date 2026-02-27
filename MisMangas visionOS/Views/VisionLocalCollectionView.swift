//
//  VisionLocalCollectionView.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 26/02/26.
//

import SwiftUI
import SwiftData

struct VisionLocalCollectionView: View {
    @Query(sort: \UserCollection.addedDate, order: .reverse) private var localCollection: [UserCollection]
    @Environment(\.modelContext) private var modelContext

    // MARK: - Stats

    private var totalMangas: Int {
        localCollection.count
    }

    private var completedMangas: Int {
        localCollection.filter { item in
            guard let total = item.manga.volumes else { return false }
            return item.currentReadingVolume == total
        }.count
    }

    private var overallProgress: Int {
        let items = localCollection.compactMap { item -> (current: Int, total: Int)? in
            guard let total = item.manga.volumes, total > 0 else { return nil }
            return (item.currentReadingVolume ?? 0, total)
        }
        guard !items.isEmpty else { return 0 }
        let totalRead = items.reduce(0) { $0 + $1.current }
        let totalVolumes = items.reduce(0) { $0 + $1.total }
        return totalVolumes > 0 ? Int((Double(totalRead) / Double(totalVolumes)) * 100) : 0
    }

    var body: some View {
        Group {
            if localCollection.isEmpty {
                ContentUnavailableView(
                    "collection_empty_title",
                    systemImage: "books.vertical",
                    description: Text("collection_empty_description")
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 50) {
                        VisionStatsHeader(
                            totalMangas: totalMangas,
                            completedMangas: completedMangas,
                            overallProgress: overallProgress,
                            isCloud: false
                        )
                        .padding(.horizontal, 60)

                        ForEach(DemographicsConfig.list) { config in
                            let items = itemsByDemographic(config.id)
                            if !items.isEmpty {
                                VisionHorizontalSection(
                                    title: config.title,
                                    icon: config.icon,
                                    color: config.color
                                ) {
                                    ForEach(items) { item in
                                        NavigationLink(value: item) {
                                            VisionLocalCollectionCard(item: item)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        let otherItems = itemsWithoutDemographic()
                        if !otherItems.isEmpty {
                            VisionHorizontalSection(
                                title: "section_other",
                                icon: "square.grid.2x2",
                                color: .gray
                            ) {
                                ForEach(otherItems) { item in
                                    NavigationLink(value: item) {
                                        VisionLocalCollectionCard(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Spacer(minLength: 60)
                    }
                    .padding(.vertical, 40)
                }
            }
        }
        .navigationTitle("nav_collection")
        .navigationDestination(for: UserCollection.self) { item in
            VisionMangaDetailView(
                item: item,
                onSave: { readingVolume, volumesOwned, isComplete in
                    item.currentReadingVolume = readingVolume
                    item.ownedVolumes.removeAll()
                    for vol in volumesOwned {
                        item.ownedVolumes.append(OwnedVolume(number: vol))
                    }
                    item.hasCompleteCollection = isComplete
                    item.lastModified = Date()
                },
                onDelete: {
                    modelContext.delete(item)
                }
            )
        }
    }

    // MARK: - Helpers

    private func itemsByDemographic(_ demographic: String) -> [UserCollection] {
        localCollection.filter { $0.manga.demographicNames.contains(demographic) }
    }

    private func itemsWithoutDemographic() -> [UserCollection] {
        localCollection.filter { $0.manga.demographicNames.isEmpty }
    }
}

#Preview(traits: .sampleData) {
    NavigationStack {
        VisionLocalCollectionView()
    }
}
