//
//  MangaDetailVMTests.swift
//  MisMangasTests
//
//  Created by Juan Carlos on 22/02/26.
//

import Testing
@testable import MisMangas

#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)

@MainActor
@Suite("Test de MangaDetailViewModel")
struct MangaDetailVMTests {
    let network: NetworkRepository
    let vm: MangaDetailViewModel

    init() {
        network = NetworkTest()
        vm = MangaDetailViewModel(manga: .test, repository: network)
    }

    @Test("Estado inicial del ViewModel")
    func checkInitialState() {
        #expect(vm.manga.id == Manga.test.id)
        #expect(vm.characters.isEmpty)
        #expect(vm.relatedMangas.isEmpty)
        #expect(vm.recommendations.isEmpty)
        #expect(vm.isLoadingCharacters == false)
        #expect(vm.isLoadingRelated == false)
        #expect(vm.isTranslating == false)
        #expect(vm.showOriginal == false)
        #expect(vm.selectedRelatedManga == nil)
    }

    @Test("Carga de datos completa")
    func checkLoadAllData() async {
        await vm.loadAllData()

        // NetworkTest devuelve arrays vacíos, pero no debe haber errores
        #expect(vm.isLoadingCharacters == false)
        #expect(vm.isLoadingRelated == false)
        #expect(vm.isTranslating == false)
    }

    @Test("Toggle de traducción")
    func checkToggleTranslation() {
        #expect(vm.showOriginal == false)

        vm.toggleTranslation()
        #expect(vm.showOriginal == true)

        vm.toggleTranslation()
        #expect(vm.showOriginal == false)
    }

    @Test("Navegación a manga relacionado")
    func checkNavigateToRelatedManga() async {
        #expect(vm.selectedRelatedManga == nil)

        await vm.loadAndNavigateToManga(id: Manga.test.id)

        #expect(vm.selectedRelatedManga != nil)
        #expect(vm.selectedRelatedManga?.id == Manga.test.id)
        #expect(vm.isLoadingManga == false)
    }

    @Test("Propiedad canTranslate")
    func checkCanTranslate() {
        // Sin TranslationService configurado, canTranslate debe ser false
        #expect(vm.canTranslate == false)
    }

    @Test("Reset de estado al cargar nuevos datos")
    func checkStateReset() async {
        // Simular estado previo
        vm.showOriginal = true

        await vm.loadAllData()

        // El estado debe resetearse
        #expect(vm.showOriginal == false)
        #expect(vm.characters.isEmpty)
        #expect(vm.relatedMangas.isEmpty)
    }

    // MARK: - ViewState Tests

    @Test("Estado inicial de ViewStates")
    func checkInitialViewStates() {
        #expect(vm.charactersState == .idle)
        #expect(vm.relatedState == .idle)
        #expect(vm.translationState == .idle)
        #expect(vm.navigationState == .idle)
    }

    @Test("ViewState se actualiza tras carga")
    func checkViewStateAfterLoad() async {
        await vm.loadAllData()

        // NetworkTest devuelve datos vacíos, así que debe ser .empty
        #expect(vm.charactersState == .empty)
        #expect(vm.relatedState == .empty)
    }

    @Test("Error en navegación establece estado error")
    func checkNavigationError() async {
        let errorNetwork = NetworkTestWithError(error: .serverError)
        let errorVM = MangaDetailViewModel(manga: .test, repository: errorNetwork)

        await errorVM.loadAndNavigateToManga(id: 999)

        #expect(errorVM.navigationState.errorMessage != nil)
        #expect(errorVM.selectedRelatedManga == nil)
    }

    @Test("Error en carga de personajes establece estado error")
    func checkCharactersError() async {
        let errorNetwork = NetworkTestWithError(error: .serverError)
        let errorVM = MangaDetailViewModel(manga: .test, repository: errorNetwork)

        await errorVM.loadAllData()

        #expect(errorVM.charactersState.errorMessage != nil)
    }
}

#endif
