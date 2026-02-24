//
//  SyncVMTests.swift
//  MisMangasTests
//
//  Created by Juan Carlos on 23/2/26.
//

#if os(iOS)
import Testing
@testable import MisMangas

@MainActor
@Suite("Test de SyncViewModel")
struct SyncVMTests {
    let authVM: AuthViewModel
    let network: NetworkRepository
    let vm: SyncViewModel

    init() {
        authVM = AuthViewModel()
        network = NetworkTest()
        vm = SyncViewModel(repository: network, authVM: authVM)
    }

    // MARK: - Estado inicial

    @Test("Estado inicial del SyncViewModel")
    func checkInitialState() {
        #expect(vm.conflicts.isEmpty)
        #expect(vm.hasConflicts == false)
        #expect(vm.state == .idle)
    }

    // MARK: - Sync sin ModelContainer

    @Test("syncToLocal sin ModelContainer retorna false")
    func checkSyncWithoutContainer() async {
        // No configuramos modelContainer
        let result = await vm.syncToLocal([])

        #expect(result == false)
    }

    // MARK: - Conflictos

    @Test("clearConflicts limpia la lista")
    func checkClearConflicts() {
        // No podemos añadir conflictos directamente, pero podemos verificar el método
        vm.clearConflicts()

        #expect(vm.conflicts.isEmpty)
        #expect(vm.hasConflicts == false)
    }

    // MARK: - Upload sin token

    @Test("uploadPendingChanges sin token no hace nada")
    func checkUploadWithoutToken() async {
        authVM.authToken = nil

        // No debería crashear
        await vm.uploadPendingChanges()

        #expect(vm.state == .idle)
    }

    // MARK: - Sync local to cloud

    @Test("syncLocalToCloud sin token no hace nada")
    func checkSyncLocalWithoutToken() async {
        authVM.authToken = nil

        await vm.syncLocalToCloud([])

        // No debería cambiar estado porque salió temprano
        #expect(vm.state == .idle)
    }

    @Test("syncLocalToCloud con lista vacía no hace nada")
    func checkSyncLocalEmpty() async {
        authVM.authToken = "test-token"

        await vm.syncLocalToCloud([])

        #expect(vm.state == .idle)
    }

    // MARK: - State Transitions

    @Test("Estado idle es el inicial")
    func checkIdleIsInitial() {
        #expect(vm.state == .idle)
        #expect(vm.conflicts.isEmpty)
    }

    @Test("hasConflicts es false cuando conflicts está vacío")
    func checkHasConflictsEmpty() {
        #expect(vm.hasConflicts == false)
    }

    @Test("clearConflicts no crashea si ya está vacío")
    func checkClearConflictsIdempotent() {
        vm.clearConflicts()
        vm.clearConflicts()
        vm.clearConflicts()

        #expect(vm.conflicts.isEmpty)
    }

    // MARK: - Network Error Tests

    @Test("syncLocalToCloud con token pero sin items no cambia estado")
    func checkSyncLocalWithTokenNoItems() async {
        authVM.authToken = "test-token"
        let items: [UserCollection] = []

        await vm.syncLocalToCloud(items)

        // No hay items, así que no debería cambiar estado
        #expect(vm.state == .idle)
    }

    // MARK: - Edge Cases

    @Test("Múltiples llamadas a uploadPendingChanges sin container")
    func checkMultipleUploadWithoutContainer() async {
        authVM.authToken = "test-token"

        // Sin modelContainer configurado
        await vm.uploadPendingChanges()
        await vm.uploadPendingChanges()

        // No debería crashear
        #expect(vm.state == .idle)
    }

    @Test("syncToLocal con colección vacía retorna false sin container")
    func checkSyncToLocalEmptyWithoutContainer() async {
        let result = await vm.syncToLocal([])

        #expect(result == false)
    }
}
#endif
