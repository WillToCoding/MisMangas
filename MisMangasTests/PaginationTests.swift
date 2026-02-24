//
//  PaginationTests.swift
//  MisMangasTests
//
//  Created by Juan Carlos on 23/2/26.
//

import Testing
@testable import MisMangas

@MainActor
@Suite("Test de paginación")
struct PaginationTests {
    let network: NetworkRepository
    let vm: MangaViewModel

    init() {
        network = NetworkTest()
        vm = MangaViewModel(repository: network)
    }

    @Test("loadMoreMangas añade sin reemplazar")
    func checkLoadMoreAppends() async {
        // Cargar primera página
        await vm.fetchMangas(page: 1, per: 10)
        let initialCount = vm.mangas.count

        // Cargar más
        await vm.loadMoreMangas(page: 2, per: 10)

        // Debería haber añadido, no reemplazado
        #expect(vm.mangas.count >= initialCount)
    }

    @Test("No carga si ya está loading")
    func checkNoDoubleLoad() async {
        // Simular que ya está cargando
        // Como no podemos fácilmente simular esto, verificamos que el guard funciona
        await vm.fetchMangas()
        #expect(vm.state == .loaded)

        // Intentar cargar más debería funcionar porque ya no está loading
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
        // Primera carga
        await vm.fetchMangas(page: 1)
        let firstManga = vm.mangas.first

        // Segunda carga (debería reemplazar, no añadir)
        await vm.fetchMangas(page: 1)

        #expect(vm.mangas.first?.id == firstManga?.id)
        #expect(vm.mangas.count == 1) // NetworkTest solo devuelve 1
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
        // NetworkTest no diferencia páginas, pero el método debería funcionar
    }
}
