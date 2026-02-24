//
//  FilterVMTests.swift
//  MisMangasTests
//
//  Created by Juan Carlos on 2/2/26.
//

import Testing
@testable import MisMangas

@MainActor
@Suite("Test de FilterViewModel")
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
        #expect(filterVM.state.errorMessage == nil)
    }

    @Test("Estado inicial de FilterViewModel")
    func checkInitialState() {
        #expect(filterVM.availableGenres.isEmpty)
        #expect(filterVM.availableDemographics.isEmpty)
        #expect(filterVM.availableThemes.isEmpty)
        #expect(filterVM.state.isLoading == false)
    }

    @Test("Error de carga establece mensaje")
    func checkLoadError() async {
        let errorNetwork = NetworkTestWithError(error: .serverError)
        let vm = FilterViewModel(repository: errorNetwork)

        await vm.loadFilterOptions()

        #expect(vm.state.errorMessage != nil)
        #expect(vm.availableGenres.isEmpty)
    }

    // MARK: - Network Error Tests

    @Test("Error 401 en carga de filtros")
    func checkUnauthorizedError() async {
        let errorNetwork = NetworkTestWithError(error: .unauthorized)
        let vm = FilterViewModel(repository: errorNetwork)

        await vm.loadFilterOptions()

        #expect(vm.state.errorMessage != nil)
        #expect(vm.state.errorMessage?.contains("401") == true)
    }

    @Test("Error timeout en carga de filtros")
    func checkTimeoutError() async {
        let errorNetwork = NetworkTestWithError(error: .timeout)
        let vm = FilterViewModel(repository: errorNetwork)

        await vm.loadFilterOptions()

        #expect(vm.state.errorMessage != nil)
        #expect(vm.availableGenres.isEmpty)
        #expect(vm.availableDemographics.isEmpty)
        #expect(vm.availableThemes.isEmpty)
    }

    @Test("Error noConnection en carga de filtros")
    func checkNoConnectionError() async {
        let errorNetwork = NetworkTestWithError(error: .noConnection)
        let vm = FilterViewModel(repository: errorNetwork)

        await vm.loadFilterOptions()

        #expect(vm.state.errorMessage != nil)
    }

    // MARK: - State Transitions

    @Test("Estado cambia a loaded tras carga exitosa")
    func checkLoadedState() async {
        await filterVM.loadFilterOptions()

        #expect(filterVM.state == .loaded)
    }

    @Test("Múltiples cargas no duplican opciones")
    func checkMultipleLoads() async {
        await filterVM.loadFilterOptions()
        let firstGenreCount = filterVM.availableGenres.count

        await filterVM.loadFilterOptions()
        let secondGenreCount = filterVM.availableGenres.count

        #expect(firstGenreCount == secondGenreCount)
        #expect(filterVM.availableGenres.count == 5)
    }

    // MARK: - Content Verification

    @Test("Géneros contienen valores esperados")
    func checkGenresContent() async {
        await filterVM.loadFilterOptions()

        #expect(filterVM.availableGenres.contains("Action"))
        #expect(filterVM.availableGenres.contains("Comedy"))
        #expect(filterVM.availableGenres.contains("Drama"))
    }

    @Test("Demografías contienen valores esperados")
    func checkDemographicsContent() async {
        await filterVM.loadFilterOptions()

        #expect(filterVM.availableDemographics.contains("Shounen"))
        #expect(filterVM.availableDemographics.contains("Seinen"))
        #expect(filterVM.availableDemographics.contains("Shoujo"))
    }

    @Test("Temas contienen valores esperados")
    func checkThemesContent() async {
        await filterVM.loadFilterOptions()

        #expect(filterVM.availableThemes.contains("School"))
        #expect(filterVM.availableThemes.contains("Martial Arts"))
    }
}
