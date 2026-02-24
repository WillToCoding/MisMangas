//
//  MangaVMErrorTests.swift
//  MisMangasTests
//
//  Created by Juan Carlos on 23/2/26.
//

import Testing
@testable import MisMangas

// MARK: - Error Handling Tests

@MainActor
@Suite("Test de errores de red")
struct MangaVMErrorTests {

    @Test("Error 401 establece estado error")
    func checkUnauthorizedError() async {
        let network = NetworkTestWithError(error: .unauthorized)
        let vm = MangaViewModel(repository: network)

        await vm.fetchMangas()

        #expect(vm.mangas.isEmpty)
        if case .error(let message) = vm.state {
            #expect(message.contains("401"))
        } else {
            Issue.record("Estado debería ser .error")
        }
    }

    @Test("Error 500 establece estado error")
    func checkServerError() async {
        let network = NetworkTestWithError(error: .serverError)
        let vm = MangaViewModel(repository: network)

        await vm.fetchMangas()

        #expect(vm.mangas.isEmpty)
        if case .error(let message) = vm.state {
            #expect(message.contains("500"))
        } else {
            Issue.record("Estado debería ser .error")
        }
    }

    @Test("Error timeout establece estado error")
    func checkTimeoutError() async {
        let network = NetworkTestWithError(error: .timeout)
        let vm = MangaViewModel(repository: network)

        await vm.fetchMangas()

        #expect(vm.mangas.isEmpty)
        if case .error(let message) = vm.state {
            #expect(message.contains("timed out"))
        } else {
            Issue.record("Estado debería ser .error")
        }
    }

    @Test("Error de búsqueda establece estado error")
    func checkSearchError() async {
        let network = NetworkTestWithError(error: .serverError)
        let vm = MangaViewModel(repository: network)

        await vm.searchMangas(text: "Dragon")

        #expect(vm.mangas.isEmpty)
        #expect(vm.state.errorMessage != nil)
    }

    @Test("Estado inicial es idle")
    func checkInitialState() {
        let vm = MangaViewModel(repository: NetworkTest())
        #expect(vm.state == .idle)
    }

    @Test("Estado loading durante carga")
    func checkLoadingState() async {
        let vm = MangaViewModel(repository: NetworkTest())
        #expect(vm.state == .idle)

        // Después de cargar, debería ser .loaded
        await vm.fetchMangas()
        #expect(vm.state == .loaded)
    }
}
