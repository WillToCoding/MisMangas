//
//  CloudCollectionSyncTests.swift
//  MisMangasTests
//
//  Created by Juan Carlos on 23/2/26.
//

#if os(iOS)
import Testing
@testable import MisMangas

@MainActor
@Suite("Test de CloudCollection con Sync")
struct CloudCollectionSyncTests {
    let authVM: AuthViewModel
    let vm: CloudCollectionViewModel

    init() {
        authVM = AuthViewModel()
        vm = CloudCollectionViewModel(authVM: authVM, repository: NetworkTest())
    }

    @Test("CloudCollectionVM tiene SyncVM configurado")
    func checkSyncVMExists() {
        // syncVM no es opcional, verificamos que está inicializado correctamente
        #expect(vm.syncVM.state == .idle)
    }

    @Test("syncConflicts delega a SyncVM")
    func checkConflictsDelegation() {
        #expect(vm.syncConflicts.isEmpty)
        #expect(vm.hasConflicts == false)
    }

    @Test("clearCollection limpia conflictos de SyncVM")
    func checkClearCollectionClearsSync() {
        vm.clearCollection()

        #expect(vm.syncConflicts.isEmpty)
        #expect(vm.state == .idle)
    }

    @Test("loadCollection con token carga y sincroniza")
    func checkLoadCollectionSyncs() async {
        authVM.authToken = "test-token"

        await vm.loadCollection()

        // Debería cargar (aunque vacío en NetworkTest)
        #expect(vm.state == .empty || vm.state == .loaded)
    }
}
#endif
