//
//  CollectionItem.swift
//  MisMangas
//
//  Created by Juan Carlos on 1/2/26.
//

import Foundation

/// Protocolo que unifica UserCollection (local) y UserMangaCollection (cloud)
protocol CollectionItem: Identifiable {
    var collectionTitle: String { get }
    var collectionCoverURL: URL? { get }
    var collectionScore: Double { get }
    var collectionVolumesOwned: [Int] { get }
    var collectionTotalVolumes: Int? { get }
    var collectionReadingVolume: Int? { get }
    var collectionIsComplete: Bool { get }
    var collectionReadingStatus: ReadingStatus { get }
    var isCloudSynced: Bool { get }
}

// MARK: - UserMangaCollection Conformance (Cloud/API)
extension UserMangaCollection: CollectionItem {
    var collectionTitle: String { manga.title }
    var collectionCoverURL: URL? { manga.coverURL }
    var collectionScore: Double { manga.score }
    var collectionVolumesOwned: [Int] { volumesOwned }
    var collectionTotalVolumes: Int? { manga.volumes }
    var collectionReadingVolume: Int? { readingVolume }
    var collectionIsComplete: Bool { completeCollection }
    var collectionReadingStatus: ReadingStatus { completeCollection ? .completed : .reading }
    var isCloudSynced: Bool { true }
}
