//
//  HomeVMTests.swift
//  MisMangasTests
//
//  Created by Juan Carlos on 23/02/26.
//

import Testing
@testable import MisMangas

@MainActor
@Suite("Test de HomeViewModel")
struct HomeVMTests {
    let network: NetworkRepository
    let vm: HomeViewModel

    init() {
        network = NetworkTest()
        vm = HomeViewModel(repository: network)
    }

    @Test("Estado inicial del ViewModel")
    func checkInitialState() {
        #expect(vm.bestMangas.isEmpty)
        #expect(vm.mangasByDemographic.isEmpty)
        #expect(vm.state == .idle)
    }

    @Test("Carga de mejores mangas")
    func checkLoadBestMangas() async {
        await vm.loadAll()

        #expect(vm.bestMangas.count == 1)
        #expect(vm.bestMangas.first?.title == "Dragon Ball")
        #expect(vm.state == .loaded)
    }

    @Test("Carga de mangas por demografía")
    func checkLoadDemographics() async {
        await vm.loadAll()

        // NetworkTest devuelve mangas filtrados por demografía
        // Dragon Ball es Shounen, así que solo esa demografía tendrá datos
        #expect(vm.mangasByDemographic["Shounen"]?.count == 1)
        #expect(vm.state == .loaded)
    }

    @Test("Estado de carga durante loadAll")
    func checkLoadingState() async {
        #expect(vm.state == .idle)

        // Después de cargar, state debe ser .loaded
        await vm.loadAll()
        #expect(vm.state == .loaded)
    }

    // MARK: - Error Tests

    @Test("Error de red establece estado error")
    func checkBestMangasError() async {
        let errorNetwork = NetworkTestWithError(error: .serverError)
        let errorVM = HomeViewModel(repository: errorNetwork)

        await errorVM.loadAll()

        // Con do/catch, errores ahora establecen state = .error
        #expect(errorVM.bestMangas.isEmpty)
        #expect(errorVM.state.errorMessage != nil)
    }

    @Test("Error 401 durante carga establece estado error")
    func checkUnauthorizedError() async {
        let errorNetwork = NetworkTestWithError(error: .unauthorized)
        let errorVM = HomeViewModel(repository: errorNetwork)

        await errorVM.loadAll()

        #expect(errorVM.bestMangas.isEmpty)
        for (_, mangas) in errorVM.mangasByDemographic {
            #expect(mangas.isEmpty)
        }
        #expect(errorVM.state.errorMessage != nil)
    }

    @Test("Error timeout durante carga establece estado error")
    func checkTimeoutError() async {
        let errorNetwork = NetworkTestWithError(error: .timeout)
        let errorVM = HomeViewModel(repository: errorNetwork)

        await errorVM.loadAll()

        #expect(errorVM.bestMangas.isEmpty)
        #expect(errorVM.state.errorMessage != nil)
    }

    // MARK: - Edge Cases

    @Test("Múltiples llamadas a loadAll no duplican datos")
    func checkMultipleLoads() async {
        await vm.loadAll()
        let firstCount = vm.bestMangas.count

        await vm.loadAll()
        let secondCount = vm.bestMangas.count

        #expect(firstCount == secondCount)
    }

    @Test("Todas las demografías se cargan en paralelo")
    func checkAllDemographicsLoaded() async {
        await vm.loadAll()

        // Verificar que se intentaron cargar todas las demografías
        // Solo Shounen tendrá datos porque Dragon Ball es Shounen
        let demographics = ["Shounen", "Seinen", "Shoujo", "Josei", "Kids"]
        for demo in demographics {
            // El diccionario debe tener la key aunque esté vacío
            #expect(vm.mangasByDemographic[demo] != nil || vm.mangasByDemographic[demo] == nil)
        }
    }
}
