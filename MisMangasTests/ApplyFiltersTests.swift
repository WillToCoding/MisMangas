//
//  ApplyFiltersTests.swift
//  MisMangasTests
//
//  Created by Juan Carlos on 23/2/26.
//

import Testing
@testable import MisMangas

@MainActor
@Suite("Test de aplicación de filtros")
struct ApplyFiltersTests {
    let network: NetworkRepository
    let vm: MangaViewModel

    init() {
        network = NetworkTest()
        vm = MangaViewModel(repository: network)
    }

    @Test("Filtro por demografía única carga mangas")
    func checkSingleDemographicFilter() async {
        vm.filters.demographics.insert("Shounen")

        await vm.applyFilters()

        #expect(vm.mangas.count == 1) // Dragon Ball es Shounen
        #expect(vm.state == .loaded)
    }

    @Test("Sin filtros carga todos los mangas")
    func checkNoFilters() async {
        await vm.applyFilters()

        #expect(vm.mangas.count == 1)
        #expect(vm.state == .loaded)
    }

    @Test("Filtro con texto usa búsqueda")
    func checkSearchTextFilter() async {
        vm.filters.searchText = "Dragon"

        await vm.applyFilters()

        #expect(vm.mangas.first?.title.contains("Dragon") == true)
    }

    @Test("Ordenamiento por score funciona")
    func checkSortByScore() async {
        vm.filters.sortBy = .score

        await vm.applyFilters()

        #expect(vm.state == .loaded)
    }

    @Test("Ordenamiento por título funciona")
    func checkSortByTitle() async {
        vm.filters.sortBy = .title

        await vm.applyFilters()

        #expect(vm.state == .loaded)
    }

    @Test("Error en filtros establece estado error")
    func checkFilterError() async {
        let errorNetwork = NetworkTestWithError(error: .serverError)
        let errorVM = MangaViewModel(repository: errorNetwork)

        await errorVM.applyFilters()

        #expect(errorVM.state.errorMessage != nil)
    }
}
