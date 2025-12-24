//
//  MangaViewModel.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import Foundation

@MainActor
@Observable
final class MangaViewModel {
    var mangas: [Manga] = []
    var metadata: Metadata?
    var isLoading = false
    var errorMessage: String?
    var filters = MangaFilters() // Sistema de filtros
    
    let repository = NetworkRepository()

    // MARK: - Fetch Methods

    /// Obtiene los mangas con paginación
    func fetchMangas(page: Int = 1, per: Int = 10) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await repository.getMangas(page: page, per: per)
            mangas = response.items
            metadata = response.metadata
        } catch {
            errorMessage = "Error al cargar mangas: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Obtiene los mejores mangas ordenados por puntuación
    func fetchBestMangas(page: Int = 1, per: Int = 10) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await repository.getBestMangas(page: page, per: per)
            mangas = response.items
            metadata = response.metadata
        } catch {
            errorMessage = "Error al cargar mejores mangas: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Busca mangas por texto
    func searchMangas(text: String, contains: Bool = true, page: Int = 1, per: Int = 10) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = if contains {
                try await repository.searchMangasContains(text, page: page, per: per)
            } else {
                try await repository.searchMangasBeginsWith(text, page: page, per: per)
            }
            mangas = response.items
            metadata = response.metadata
        } catch {
            errorMessage = "Error al buscar mangas: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Obtiene mangas por género
    func fetchMangasByGenre(_ genre: String, page: Int = 1, per: Int = 10) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await repository.getMangasByGenre(genre, page: page, per: per)
            mangas = response.items
            metadata = response.metadata
        } catch {
            errorMessage = "Error al cargar mangas por género: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Obtiene mangas por demografía
    func fetchMangasByDemographic(_ demographic: String, page: Int = 1, per: Int = 10) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await repository.getMangasByDemographic(demographic, page: page, per: per)
            mangas = response.items
            metadata = response.metadata
        } catch {
            errorMessage = "Error al cargar mangas por demografía: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Carga más mangas (paginación)
    func loadMoreMangas(page: Int, per: Int = 10) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await repository.getMangas(page: page, per: per)
            mangas.append(contentsOf: response.items)
            metadata = response.metadata
        } catch {
            errorMessage = "Error al cargar más mangas: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Filter Methods

    /// Aplica los filtros combinados y actualiza la lista de mangas
    func applyFilters(page: Int = 1, per: Int = 10) async {
        isLoading = true
        errorMessage = nil

        do {
            // Si hay filtros avanzados (año, score), usar Jikan API
            if filters.hasAdvancedFilters {
                try await applyJikanFilters(page: page, limit: per)
            }
            // Si hay filtros múltiples, usar POST /search/manga
            else if filters.genres.count > 0 || filters.demographics.count > 0 || filters.themes.count > 0 {
                let customSearch = CustomSearch(
                    searchTitle: filters.searchText.isEmpty ? nil : filters.searchText,
                    searchAuthorFirstName: nil,
                    searchAuthorLastName: nil,
                    searchGenres: filters.genres.isEmpty ? nil : Array(filters.genres),
                    searchThemes: filters.themes.isEmpty ? nil : Array(filters.themes),
                    searchDemographics: filters.demographics.isEmpty ? nil : Array(filters.demographics),
                    searchContains: true
                )

                let response = try await repository.searchCustom(customSearch, page: page, per: per)
                mangas = response.items
                metadata = response.metadata
            }
            // Si solo hay un género, usar endpoint específico
            else if let genre = filters.genres.first {
                let response = try await repository.getMangasByGenre(genre, page: page, per: per)
                mangas = response.items
                metadata = response.metadata
            }
            // Si solo hay una demografía
            else if let demographic = filters.demographics.first {
                let response = try await repository.getMangasByDemographic(demographic, page: page, per: per)
                mangas = response.items
                metadata = response.metadata
            }
            // Si solo hay un tema
            else if let theme = filters.themes.first {
                let response = try await repository.getMangasByTheme(theme, page: page, per: per)
                mangas = response.items
                metadata = response.metadata
            }
            // Si solo hay búsqueda por texto
            else if !filters.searchText.isEmpty {
                let response = try await repository.searchMangasContains(filters.searchText, page: page, per: per)
                mangas = response.items
                metadata = response.metadata
            }
            // Sin filtros, cargar todos
            else {
                let response = try await repository.getMangas(page: page, per: per)
                mangas = response.items
                metadata = response.metadata
            }

            // Aplicar ordenamiento local
            sortMangas(by: filters.sortBy)
        } catch {
            errorMessage = "Error al aplicar filtros: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Aplica filtros avanzados usando Jikan API (año, score, status)
    private func applyJikanFilters(page: Int = 1, limit: Int = 25) async throws {
        let response = try await repository.searchMangasJikan(
            query: filters.searchText.isEmpty ? nil : filters.searchText,
            genres: nil, // Jikan usa IDs numéricos para géneros
            minScore: filters.minScore,
            maxScore: nil,
            startYear: filters.startYear,
            endYear: filters.endYear,
            status: filters.status?.jikanValue,
            orderBy: jikanOrderBy,
            sort: jikanSortOrder,
            page: page,
            limit: limit
        )

        // Convertir JikanManga a Manga
        mangas = response.data.map { $0.toManga() }

        // Crear metadata aproximada desde la paginación de Jikan
        metadata = Metadata(
            total: response.pagination.lastVisiblePage * limit,
            page: response.pagination.currentPage,
            per: limit
        )
    }

    /// Convierte SortOption a orderBy de Jikan
    private var jikanOrderBy: String {
        switch filters.sortBy {
        case .score: return "score"
        case .title: return "title"
        case .recent: return "start_date"
        }
    }

    /// Orden de Jikan según el criterio
    private var jikanSortOrder: String {
        switch filters.sortBy {
        case .score, .recent: return "desc"
        case .title: return "asc"
        }
    }

    /// Ordena los mangas según el criterio seleccionado
    private func sortMangas(by option: SortOption) {
        switch option {
        case .score:
            mangas.sort { $0.score > $1.score }
        case .title:
            mangas.sort { $0.title < $1.title }
        case .recent:
            mangas.sort { ($0.startDate ?? "") > ($1.startDate ?? "") }
        }
    }
}
