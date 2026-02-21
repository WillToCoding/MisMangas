//
//  FilterVMTests.swift
//  MisMangasTests
//
//  Created by Juan Carlos on 2/2/26.
//

import Testing
@testable import MisMangas

@MainActor
@Suite("Test de filtros")
struct FilterVMTests {
    let network: NetworkRepository
    let filterVM: FilterViewModel

    init() {
        network = NetworkTest()
        filterVM = FilterViewModel(repository: network)
    }

    @Test("Comprueba la carga de opciones de filtros")
    func checkFilterOptionsCarga() async {
        await filterVM.loadFilterOptions()
        #expect(filterVM.availableGenres.count == 5)
        #expect(filterVM.availableDemographics.count == 4)
        #expect(filterVM.availableThemes.count == 4)
        #expect(filterVM.errorMessage == nil)
    }
}
