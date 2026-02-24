//
//  MangaVMTests.swift
//  MisMangasTests
//
//  Created by Juan Carlos on 2/2/26.
//

import Testing
@testable import MisMangas

@MainActor
@Suite("Test de carga de mangas")
struct MangaVMTests {
    let network: NetworkRepository
    let vm: MangaViewModel

    init() {
        network = NetworkTest()
        vm = MangaViewModel(repository: network)
    }

    @Test("Comprueba la carga desde Network")
    func checkMangasCarga() async throws {
        let response = try await network.getMangas(page: 1, per: 10)
        #expect(response.items.count == 1)
    }

    @Test("Comprueba la carga de mangas en el VM")
    func checkMangasCargaVM() async {
        await vm.fetchMangas()
        #expect(vm.mangas.count == 1)
        #expect(vm.state == .loaded)
    }

    @Test("Comprueba el ordenamiento por score")
    func checkMangasSort() async {
        await vm.fetchMangas()
        vm.filters.sortBy = .score
        #expect(vm.mangas.first?.title == "Dragon Ball")
    }
}
