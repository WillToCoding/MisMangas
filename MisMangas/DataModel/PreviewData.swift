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
        let schema = Schema([MangaModel.self, UserCollection.self, OwnedVolume.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: configuration)

        insertSampleData()
    }

    private func insertSampleData() {
        let context = container.mainContext

        // Ejemplo 1: Dragon Ball - Colección completa
        let dragonBallManga = MangaModel(
            id: 42,
            title: "Dragon Ball",
            titleEnglish: "Dragon Ball",
            titleJapanese: "ドラゴンボール",
            status: "finished",
            score: 8.41,
            volumes: 42,
            chapters: 520,
            sypnosis: "Bulma, a headstrong 16-year-old girl, is on a quest to find the mythical Dragon Balls.",
            mainPicture: "https://cdn.myanimelist.net/images/manga/1/267793l.jpg",
            url: "https://myanimelist.net/manga/42",
            authorNames: ["Akira Toriyama"],
            genreNames: ["Action", "Adventure", "Comedy"],
            themeNames: ["Martial Arts"],
            demographicNames: ["Shounen"]
        )
        context.insert(dragonBallManga)

        let dragonBall = UserCollection(
            manga: dragonBallManga,
            volumesOwned: Array(1...42),
            currentReadingVolume: 30,
            hasCompleteCollection: true
        )
        context.insert(dragonBall)

        // Ejemplo 2: Berserk - Lectura en progreso
        let berserkManga = MangaModel(
            id: 2,
            title: "Berserk",
            titleEnglish: "Berserk",
            status: "on_hiatus",
            score: 9.47,
            volumes: 41,
            sypnosis: "Guts, a former mercenary now known as the Black Swordsman, is out for revenge.",
            mainPicture: "https://cdn.myanimelist.net/images/manga/1/157897l.jpg",
            url: "https://myanimelist.net/manga/2",
            authorNames: ["Kentaro Miura"],
            genreNames: ["Action", "Drama", "Fantasy"],
            themeNames: ["Gore", "Military"],
            demographicNames: ["Seinen"]
        )
        context.insert(berserkManga)

        let berserk = UserCollection(
            manga: berserkManga,
            volumesOwned: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            currentReadingVolume: 8,
            hasCompleteCollection: false
        )
        context.insert(berserk)

        // Ejemplo 3: Monster - Algunos volúmenes
        let monsterManga = MangaModel(
            id: 1,
            title: "Monster",
            titleEnglish: "Monster",
            status: "finished",
            score: 9.15,
            volumes: 18,
            sypnosis: "Dr. Kenzou Tenma is a renowned brain surgeon of Japanese descent working in Europe.",
            mainPicture: "https://cdn.myanimelist.net/images/manga/3/258224l.jpg",
            url: "https://myanimelist.net/manga/1",
            authorNames: ["Naoki Urasawa"],
            genreNames: ["Drama", "Mystery"],
            themeNames: ["Psychological"],
            demographicNames: ["Seinen"]
        )
        context.insert(monsterManga)

        let monster = UserCollection(
            manga: monsterManga,
            volumesOwned: [1, 2, 3],
            currentReadingVolume: 2,
            hasCompleteCollection: false
        )
        context.insert(monster)

        try? context.save()
    }

    var context: ModelContext {
        container.mainContext
    }

    var allCollections: [UserCollection] {
        let descriptor = FetchDescriptor<UserCollection>(
            sortBy: [SortDescriptor(\.addedDate, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    var sampleCollection: UserCollection {
        allCollections[0]
    }

    var allCachedMangas: [MangaModel] {
        let descriptor = FetchDescriptor<MangaModel>(
            sortBy: [SortDescriptor(\.title)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
