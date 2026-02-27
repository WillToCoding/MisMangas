//
//  CollectionView+Stats.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI

// MARK: - Stats Calculations

extension CollectionView {
    var cloudCompletedCount: Int {
        cloudVM.cloudCollection.filter { $0.completeCollection }.count
    }

    var cloudOverallProgress: Int {
        let items = cloudVM.cloudCollection
        guard !items.isEmpty else { return 0 }
        let totalProgress = items.reduce(0.0) { acc, item in
            let total = item.manga.volumes ?? 1
            let owned = item.volumesOwned.count
            return acc + min(1.0, Double(owned) / Double(total))
        }
        return Int((totalProgress / Double(items.count)) * 100)
    }

    var localCompletedCount: Int {
        localCollection.filter { $0.hasCompleteCollection }.count
    }

    var localOverallProgress: Int {
        guard !localCollection.isEmpty else { return 0 }
        let totalProgress = localCollection.reduce(0.0) { acc, item in
            let total = item.totalVolumes ?? 1
            let owned = item.volumesOwned.count
            return acc + min(1.0, Double(owned) / Double(total))
        }
        return Int((totalProgress / Double(localCollection.count)) * 100)
    }
}

// MARK: - Grouping (Cloud)

extension CollectionView {
    func cloudItemsByDemographic(_ demographic: String) -> [UserMangaCollection] {
        cloudVM.cloudCollection
            .filter { $0.manga.demographics.contains { $0.demographic == demographic } }
    }

    func cloudItemsWithoutDemographic() -> [UserMangaCollection] {
        cloudVM.cloudCollection
            .filter { $0.manga.demographics.isEmpty }
    }
}

// MARK: - Grouping (Local)

extension CollectionView {
    func localItemsByDemographic(_ demographic: String) -> [UserCollection] {
        localCollection
            .filter { $0.manga.demographicNames.contains(demographic) }
    }

    func localItemsWithoutDemographic() -> [UserCollection] {
        localCollection
            .filter { $0.manga.demographicNames.isEmpty }
    }
}
