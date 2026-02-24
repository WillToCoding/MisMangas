//
//  MangaFiltersTests.swift
//  MisMangasTests
//
//  Created by Juan Carlos on 23/2/26.
//

import Testing
@testable import MisMangas

// MARK: - MangaFilters Tests

@Suite("Test de MangaFilters")
struct MangaFiltersTests {

    @Test("Estado inicial de filtros")
    func checkInitialState() {
        let filters = MangaFilters()

        #expect(filters.genres.isEmpty)
        #expect(filters.demographics.isEmpty)
        #expect(filters.themes.isEmpty)
        #expect(filters.searchText.isEmpty)
        #expect(filters.sortBy == .score)
        #expect(filters.isActive == false)
    }

    @Test("isActive true con género seleccionado")
    func checkIsActiveWithGenre() {
        var filters = MangaFilters()
        filters.genres.insert("Action")

        #expect(filters.isActive == true)
    }

    @Test("isActive true con demografía seleccionada")
    func checkIsActiveWithDemographic() {
        var filters = MangaFilters()
        filters.demographics.insert("Shounen")

        #expect(filters.isActive == true)
    }

    @Test("isActive true con texto de búsqueda")
    func checkIsActiveWithSearchText() {
        var filters = MangaFilters()
        filters.searchText = "Dragon"

        #expect(filters.isActive == true)
    }

    @Test("hasAdvancedFilters true con minScore")
    func checkHasAdvancedWithScore() {
        var filters = MangaFilters()
        filters.minScore = 8.0

        #expect(filters.hasAdvancedFilters == true)
        #expect(filters.isActive == true)
    }

    @Test("hasAdvancedFilters true con año")
    func checkHasAdvancedWithYear() {
        var filters = MangaFilters()
        filters.startYear = 2020

        #expect(filters.hasAdvancedFilters == true)
    }

    @Test("clear limpia todos los filtros")
    func checkClear() {
        var filters = MangaFilters()
        filters.genres.insert("Action")
        filters.demographics.insert("Shounen")
        filters.searchText = "Dragon"
        filters.minScore = 8.0
        filters.startYear = 2020

        filters.clear()

        #expect(filters.genres.isEmpty)
        #expect(filters.demographics.isEmpty)
        #expect(filters.searchText.isEmpty)
        #expect(filters.minScore == nil)
        #expect(filters.startYear == nil)
        #expect(filters.isActive == false)
    }

    @Test("cleared retorna copia limpia")
    func checkCleared() {
        var filters = MangaFilters()
        filters.genres.insert("Action")

        let clean = filters.cleared()

        #expect(clean.genres.isEmpty)
        #expect(filters.genres.contains("Action")) // Original sin modificar
    }
}
