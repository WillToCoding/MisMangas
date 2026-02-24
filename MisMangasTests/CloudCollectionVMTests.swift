//
//  CloudCollectionVMTests.swift
//  MisMangasTests
//
//  Created by Juan Carlos on 23/02/26.
//

import Testing
@testable import MisMangas

@MainActor
@Suite("Test de CloudCollectionViewModel")
struct CloudCollectionVMTests {
    let authVM: AuthViewModel
    let vm: CloudCollectionViewModel

    init() {
        authVM = AuthViewModel()
        vm = CloudCollectionViewModel(authVM: authVM)
    }

    // MARK: - Estado inicial

    @Test("Estado inicial del ViewModel")
    func checkInitialState() {
        #expect(vm.cloudCollection.isEmpty)
        #expect(vm.state == .idle)
    }

    // MARK: - Helper Methods

    @Test("isInCollection devuelve false con colección vacía")
    func checkIsInCollectionEmpty() {
        #expect(vm.isInCollection(42) == false)
        #expect(vm.isInCollection(1) == false)
    }

    @Test("getMangaCollection devuelve nil con colección vacía")
    func checkGetMangaCollectionEmpty() {
        #expect(vm.getMangaCollection(42) == nil)
    }

    @Test("clearCollection limpia el estado")
    func checkClearCollection() {
        // Given: forzamos un estado de error
        // (No podemos asignar directamente pero clearCollection resetea a .idle)

        // When: limpiamos
        vm.clearCollection()

        // Then: todo limpio
        #expect(vm.cloudCollection.isEmpty)
        #expect(vm.state == .idle)
    }

    // MARK: - Autenticación

    @Test("loadCollection sin token establece estado error")
    func checkLoadCollectionWithoutToken() async {
        // Given: usuario no autenticado
        authVM.authToken = nil
        authVM.isAuthenticated = false

        // When: intentamos cargar
        await vm.loadCollection()

        // Then: error de autenticación
        #expect(vm.state.errorMessage != nil)
        #expect(vm.cloudCollection.isEmpty)
    }

    @Test("addToCollection sin token lanza error")
    func checkAddWithoutToken() async {
        // Given: usuario no autenticado
        authVM.authToken = nil

        // When/Then: lanza AuthError.noToken
        do {
            try await vm.addToCollection(
                manga: .test,
                volumesOwned: [1, 2, 3],
                readingVolume: 2,
                completeCollection: false
            )
            #expect(Bool(false), "Debería lanzar error")
        } catch AuthError.noToken {
            // Correcto
        } catch {
            #expect(Bool(false), "Debería ser AuthError.noToken")
        }
    }

    @Test("removeFromCollection sin token lanza error")
    func checkRemoveWithoutToken() async {
        // Given: usuario no autenticado
        authVM.authToken = nil

        // When/Then: lanza AuthError.noToken
        do {
            try await vm.removeFromCollection(mangaId: 42)
            #expect(Bool(false), "Debería lanzar error")
        } catch AuthError.noToken {
            // Correcto
        } catch {
            #expect(Bool(false), "Debería ser AuthError.noToken")
        }
    }

    // MARK: - Network Error Tests

    @Test("loadCollection con error de red establece estado error")
    func checkLoadCollectionNetworkError() async {
        let errorNetwork = NetworkTestWithError(error: .serverError)
        let errorVM = CloudCollectionViewModel(authVM: authVM, repository: errorNetwork)
        authVM.authToken = "valid-token"

        await errorVM.loadCollection()

        #expect(errorVM.state.errorMessage != nil)
        #expect(errorVM.cloudCollection.isEmpty)
    }

    @Test("loadCollection con error 401 cierra sesión")
    func checkLoadCollectionUnauthorized() async {
        let errorNetwork = NetworkTestWithError(error: .unauthorized)
        let errorVM = CloudCollectionViewModel(authVM: authVM, repository: errorNetwork)
        authVM.authToken = "expired-token"
        authVM.isAuthenticated = true

        await errorVM.loadCollection()

        // El error 401 debería cerrar la sesión
        #expect(authVM.isAuthenticated == false)
    }

    @Test("addToCollection con error de red propaga el error")
    func checkAddToCollectionNetworkError() async {
        let errorNetwork = NetworkTestWithError(error: .serverError)
        let errorVM = CloudCollectionViewModel(authVM: authVM, repository: errorNetwork)
        authVM.authToken = "valid-token"

        do {
            try await errorVM.addToCollection(
                manga: .test,
                volumesOwned: [1],
                readingVolume: 1,
                completeCollection: false
            )
            #expect(Bool(false), "Debería lanzar error")
        } catch {
            // Error esperado
            #expect(errorVM.state.errorMessage != nil)
        }
    }

    @Test("removeFromCollection con error de red propaga el error")
    func checkRemoveFromCollectionNetworkError() async {
        let errorNetwork = NetworkTestWithError(error: .serverError)
        let errorVM = CloudCollectionViewModel(authVM: authVM, repository: errorNetwork)
        authVM.authToken = "valid-token"

        do {
            try await errorVM.removeFromCollection(mangaId: 1)
            #expect(Bool(false), "Debería lanzar error")
        } catch {
            // Error esperado
            #expect(errorVM.state.errorMessage != nil)
        }
    }

    // MARK: - Success Flow Tests

    @Test("loadCollection con token carga correctamente")
    func checkLoadCollectionSuccess() async {
        let successNetwork = NetworkTest()
        let successVM = CloudCollectionViewModel(authVM: authVM, repository: successNetwork)
        authVM.authToken = "valid-token"

        await successVM.loadCollection()

        // NetworkTest devuelve colección vacía
        #expect(successVM.state == .empty)
    }

    @Test("Estado empty cuando colección está vacía")
    func checkEmptyState() async {
        let successNetwork = NetworkTest()
        let successVM = CloudCollectionViewModel(authVM: authVM, repository: successNetwork)
        authVM.authToken = "valid-token"

        await successVM.loadCollection()

        #expect(successVM.state == .empty)
        #expect(successVM.cloudCollection.isEmpty)
    }
}
