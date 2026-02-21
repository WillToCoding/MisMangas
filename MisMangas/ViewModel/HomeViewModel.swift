//
//  HomeViewModel.swift
//  MisMangas
//
//  Created by Juan Carlos on 2/2/26.
//

import Foundation

@MainActor
@Observable
final class HomeViewModel {
    var bestMangas: [Manga] = []
    var mangasByDemographic: [String: [Manga]] = [:]
    var isLoading = false

    private let repository: NetworkRepository
    private let demographics = ["Shounen", "Seinen", "Shoujo", "Josei", "Kids"]

    init(repository: NetworkRepository = Network()) {
        self.repository = repository
    }

    func loadAll() async {
        isLoading = true

        async let best: () = loadBest()
        async let demos: () = loadDemographics()
        _ = await (best, demos)

        isLoading = false
    }

    private func loadBest() async {
        if let response = try? await repository.getBestMangas(page: 1, per: 10) {
            bestMangas = response.items
        }
    }

    private func loadDemographics() async {
        await withTaskGroup(of: (String, [Manga]).self) { group in
            for demo in demographics {
                group.addTask {
                    let mangas = (try? await self.repository.getMangasByDemographic(demo, page: 1, per: 10))?.items ?? []
                    return (demo, mangas)
                }
            }
            for await (demo, mangas) in group {
                mangasByDemographic[demo] = mangas
            }
        }
    }
}
