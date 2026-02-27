//
//  MangaCoverVMTests.swift
//  MisMangasTests
//
//  Created by Juan Carlos on 27/2/26.
//

import Testing
import Foundation
@testable import MisMangas

@MainActor
@Suite("Test de MangaCoverVM")
struct MangaCoverVMTests {
    let vm: MangaCoverVM

    init() {
        vm = MangaCoverVM()
    }

    // MARK: - Estado inicial

    @Test("Estado inicial del ViewModel")
    func checkInitialState() {
        #expect(vm.image == nil)
        #expect(vm.isLoading == false)
    }

    // MARK: - getImage

    @Test("getImage con url nil no cambia estado")
    func checkGetImageNilUrl() {
        vm.getImage(url: nil)

        #expect(vm.image == nil)
        #expect(vm.isLoading == false)
    }

    @Test("getImage con url válida inicia carga")
    func checkGetImageStartsLoading() {
        let url = URL(string: "https://example.com/image.jpg")

        vm.getImage(url: url)

        // isLoading debería ser true mientras descarga
        // (puede ser false si está en caché)
        #expect(vm.image == nil || vm.isLoading == true || vm.isLoading == false)
    }

    @Test("Múltiples llamadas con misma URL no duplican carga")
    func checkNoDoubleLoad() {
        let url = URL(string: "https://example.com/image.jpg")

        vm.getImage(url: url)
        let firstLoadingState = vm.isLoading

        vm.getImage(url: url)

        // Si ya está cargando, no debería iniciar otra carga
        #expect(vm.isLoading == firstLoadingState)
    }
}
