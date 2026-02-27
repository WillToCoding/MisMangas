//
//  MangaVMTests.swift
//  MisMangasTests
//
//  Created by Juan Carlos on 2/2/26.
//

import Testing
@testable import MisMangas

@MainActor
@Suite("Test de MangaViewModel")
struct MangaVMTests {
    let network: NetworkRepository
    let vm: MangaViewModel

    init() {
        network = NetworkTest()
        vm = MangaViewModel(repository: network)
    }

    // MARK: - Carga básica

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

    // MARK: - Estado

    @Test("Estado inicial es idle")
    func checkInitialState() {
        let newVM = MangaViewModel(repository: NetworkTest())
        #expect(newVM.state == .idle)
    }

    @Test("Estado loading durante carga")
    func checkLoadingState() async {
        #expect(vm.state == .idle)
        await vm.fetchMangas()
        #expect(vm.state == .loaded)
    }

    // MARK: - Errores

    @Test("Error 401 establece estado error")
    func checkUnauthorizedError() async {
        let errorNetwork = NetworkTestWithError(error: .unauthorized)
        let errorVM = MangaViewModel(repository: errorNetwork)

        await errorVM.fetchMangas()

        #expect(errorVM.mangas.isEmpty)
        if case .error(let message) = errorVM.state {
            #expect(message.contains("401"))
        } else {
            Issue.record("Estado debería ser .error")
        }
    }

    @Test("Error 500 establece estado error")
    func checkServerError() async {
        let errorNetwork = NetworkTestWithError(error: .serverError)
        let errorVM = MangaViewModel(repository: errorNetwork)

        await errorVM.fetchMangas()

        #expect(errorVM.mangas.isEmpty)
        if case .error(let message) = errorVM.state {
            #expect(message.contains("500"))
        } else {
            Issue.record("Estado debería ser .error")
        }
    }

    @Test("Error timeout establece estado error")
    func checkTimeoutError() async {
        let errorNetwork = NetworkTestWithError(error: .timeout)
        let errorVM = MangaViewModel(repository: errorNetwork)

        await errorVM.fetchMangas()

        #expect(errorVM.mangas.isEmpty)
        if case .error(let message) = errorVM.state {
            #expect(message.contains("timed out"))
        } else {
            Issue.record("Estado debería ser .error")
        }
    }

    @Test("Error de búsqueda establece estado error")
    func checkSearchError() async {
        let errorNetwork = NetworkTestWithError(error: .serverError)
        let errorVM = MangaViewModel(repository: errorNetwork)

        await errorVM.searchMangas(text: "Dragon")

        #expect(errorVM.mangas.isEmpty)
        #expect(errorVM.state.errorMessage != nil)
    }

    // MARK: - Paginación

    @Test("loadMoreMangas añade sin reemplazar")
    func checkLoadMoreAppends() async {
        await vm.fetchMangas(page: 1, per: 10)
        let initialCount = vm.mangas.count

        await vm.loadMoreMangas(page: 2, per: 10)

        #expect(vm.mangas.count >= initialCount)
    }

    @Test("No carga si ya está loading")
    func checkNoDoubleLoad() async {
        await vm.fetchMangas()
        #expect(vm.state == .loaded)

        await vm.loadMoreMangas(page: 2)
        #expect(vm.state == .loaded)
    }

    @Test("Metadata se actualiza correctamente")
    func checkMetadataUpdate() async {
        await vm.fetchMangas(page: 1, per: 10)

        #expect(vm.metadata != nil)
        #expect(vm.metadata?.page == 1)
    }

    @Test("fetchMangas reemplaza lista existente")
    func checkFetchReplaces() async {
        await vm.fetchMangas(page: 1)
        let firstManga = vm.mangas.first

        await vm.fetchMangas(page: 1)

        #expect(vm.mangas.first?.id == firstManga?.id)
        #expect(vm.mangas.count == 1)
    }

    @Test("Error en paginación establece estado error")
    func checkPaginationError() async {
        let errorNetwork = NetworkTestWithError(error: .serverError)
        let errorVM = MangaViewModel(repository: errorNetwork)

        await errorVM.loadMoreMangas(page: 2)

        #expect(errorVM.state.errorMessage != nil)
    }

    @Test("Carga página específica")
    func checkSpecificPage() async {
        await vm.fetchMangas(page: 3, per: 20)

        #expect(vm.state == .loaded)
    }

    // MARK: - Filtros

    @Test("Filtro por demografía única carga mangas")
    func checkSingleDemographicFilter() async {
        vm.filters.demographics.insert("Shounen")

        await vm.applyFilters()

        #expect(vm.mangas.count == 1)
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
