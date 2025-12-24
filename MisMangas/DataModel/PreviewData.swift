//
//  PreviewData.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import Foundation
import SwiftData

@MainActor
struct PreviewData {
    static let shared = PreviewData()

    let container: ModelContainer

    private init() {
        let schema = Schema([Model.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: configuration)

        insertSampleData()
    }

    private func insertSampleData() {
        let context = container.mainContext

        // Ejemplo 1: Dragon Ball - Colección completa
        let dragonBall = Model(
            id: 42,
            volumesOwned: Array(1...42),
            currentReadingVolume: 30,
            hasCompleteCollection: true,
            title: "Dragon Ball",
            titleEnglish: "Dragon Ball",
            mainPicture: "https://cdn.myanimelist.net/images/manga/1/267793l.jpg",
            score: 8.41,
            totalVolumes: 42
        )

        // Ejemplo 2: Berserk - Lectura en progreso
        let berserk = Model(
            id: 2,
            volumesOwned: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            currentReadingVolume: 8,
            hasCompleteCollection: false,
            title: "Berserk",
            titleEnglish: "Berserk",
            mainPicture: "https://cdn.myanimelist.net/images/manga/1/157897l.jpg",
            score: 9.47,
            totalVolumes: nil
        )

        // Ejemplo 3: Monster - Algunos volúmenes
        let monster = Model(
            id: 1,
            volumesOwned: [1, 2, 3],
            currentReadingVolume: 2,
            hasCompleteCollection: false,
            title: "Monster",
            titleEnglish: "Monster",
            mainPicture: "https://cdn.myanimelist.net/images/manga/3/258224l.jpg",
            score: 9.15,
            totalVolumes: 18
        )

        context.insert(dragonBall)
        context.insert(berserk)
        context.insert(monster)

        try? context.save()
    }

    var context: ModelContext {
        container.mainContext
    }

    var allMangas: [Model] {
        let descriptor = FetchDescriptor<Model>(
            sortBy: [SortDescriptor(\.addedDate, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
