//
//  Model.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import Foundation
import SwiftData

@Model
final class Model {
    @Attribute(.unique) var id: Int
    var volumesOwned: [Int]
    var currentReadingVolume: Int?
    var hasCompleteCollection: Bool
    var addedDate: Date

    // Datos del manga para mostrar sin necesidad de fetch
    var title: String
    var titleEnglish: String?
    var mainPicture: String
    var score: Double
    var totalVolumes: Int?

    init(
        id: Int,
        volumesOwned: [Int],
        currentReadingVolume: Int? = nil,
        hasCompleteCollection: Bool = false,
        addedDate: Date = Date(),
        title: String,
        titleEnglish: String? = nil,
        mainPicture: String,
        score: Double,
        totalVolumes: Int? = nil
    ) {
        self.id = id
        self.volumesOwned = volumesOwned
        self.currentReadingVolume = currentReadingVolume
        self.hasCompleteCollection = hasCompleteCollection
        self.addedDate = addedDate
        self.title = title
        self.titleEnglish = titleEnglish
        self.mainPicture = mainPicture
        self.score = score
        self.totalVolumes = totalVolumes
    }

    // Convenience init desde Manga
    convenience init(from manga: Manga, volumesOwned: [Int], readingVolume: Int?, hasComplete: Bool) {
        self.init(
            id: manga.id,
            volumesOwned: volumesOwned,
            currentReadingVolume: readingVolume,
            hasCompleteCollection: hasComplete,
            addedDate: Date(),
            title: manga.title,
            titleEnglish: manga.titleEnglish,
            mainPicture: manga.mainPicture,
            score: manga.score,
            totalVolumes: manga.volumes
        )
    }
}
