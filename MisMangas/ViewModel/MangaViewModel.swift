//
//  MangaViewModel.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import Foundation

/// ViewModel principal para la gestion de mangas.
///
/// `MangaViewModel` es responsable de obtener, buscar y filtrar mangas desde la API.
/// Utiliza el patron Repository para abstraer la capa de red y facilitar el testing.
///
/// ## Ejemplo de uso
///
/// ```swift
/// let viewModel = MangaViewModel()
/// await viewModel.fetchMangas(page: 1, per: 20)
///
/// for manga in viewModel.mangas {
///     print(manga.title)
/// }
/// ```
///
/// ## Topics
///
/// ### Obtencion de datos
/// - ``fetchMangas(page:per:)``
/// - ``fetchBestMangas(page:per:)``
/// - ``loadMoreMangas(page:per:)``
///
/// ### Busqueda
/// - ``searchMangas(text:contains:page:per:)``
///
/// ### Filtros
/// - ``applyFilters(page:per:)``
/// - ``fetchMangasByGenre(_:page:per:)``
/// - ``fetchMangasByDemographic(_:page:per:)``
@MainActor
@Observable
final class MangaViewModel {
    /// Lista de mangas cargados actualmente.
    var mangas: [Manga] = []

    /// Metadatos de paginacion de la ultima consulta.
    var metadata: Metadata?

    /// Indica si hay una operacion de red en curso.
    var isLoading = false

    /// Mensaje de error de la ultima operacion fallida.
    var errorMessage: String?

    /// Sistema de filtros activos para las consultas.
    var filters = MangaFilters()

    /// Repositorio de red inyectado para las operaciones de API.
    let repository: NetworkRepository

    /// Crea una nueva instancia del ViewModel.
    ///
    /// - Parameter repository: Repositorio de red a utilizar. Por defecto usa ``Network``.
    init(repository: NetworkRepository = Network()) {
        self.repository = repository
    }

    // MARK: - Fetch Methods

    /// Obtiene los mangas con paginacion desde la API.
    ///
    /// Realiza una llamada a la API de Academy para obtener el listado de mangas
    /// ordenados por defecto. Los resultados reemplazan la lista actual.
    ///
    /// - Parameters:
    ///   - page: Numero de pagina a obtener. Por defecto `1`.
    ///   - per: Cantidad de mangas por pagina. Por defecto `10`.
    ///
    /// ## Ejemplo
    ///
    /// ```swift
    /// await viewModel.fetchMangas(page: 2, per: 20)
    /// ```
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

    /// Obtiene los mejores mangas ordenados por puntuacion.
    ///
    /// Recupera los mangas con mayor puntuacion (score) de la base de datos.
    /// Ideal para mostrar recomendaciones o secciones destacadas.
    ///
    /// - Parameters:
    ///   - page: Numero de pagina a obtener. Por defecto `1`.
    ///   - per: Cantidad de mangas por pagina. Por defecto `10`.
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

    /// Busca mangas por texto en el titulo.
    ///
    /// Permite buscar mangas cuyo titulo contenga o comience con el texto especificado.
    ///
    /// - Parameters:
    ///   - text: Texto a buscar en el titulo del manga.
    ///   - contains: Si es `true`, busca mangas que contengan el texto.
    ///               Si es `false`, busca mangas que comiencen con el texto. Por defecto `true`.
    ///   - page: Numero de pagina a obtener. Por defecto `1`.
    ///   - per: Cantidad de mangas por pagina. Por defecto `10`.
    ///
    /// ## Ejemplo
    ///
    /// ```swift
    /// // Buscar mangas que contengan "dragon"
    /// await viewModel.searchMangas(text: "dragon", contains: true)
    ///
    /// // Buscar mangas que empiecen con "one"
    /// await viewModel.searchMangas(text: "one", contains: false)
    /// ```
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

    /// Obtiene mangas filtrados por genero.
    ///
    /// - Parameters:
    ///   - genre: Nombre del genero (ej: "Action", "Romance", "Comedy").
    ///   - page: Numero de pagina a obtener. Por defecto `1`.
    ///   - per: Cantidad de mangas por pagina. Por defecto `10`.
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

    /// Obtiene mangas filtrados por demografia.
    ///
    /// - Parameters:
    ///   - demographic: Nombre de la demografia (ej: "Shounen", "Seinen", "Shoujo").
    ///   - page: Numero de pagina a obtener. Por defecto `1`.
    ///   - per: Cantidad de mangas por pagina. Por defecto `10`.
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

    /// Carga mas mangas para paginacion infinita.
    ///
    /// A diferencia de ``fetchMangas(page:per:)``, este metodo **agrega** los resultados
    /// a la lista existente en lugar de reemplazarla. Ideal para implementar scroll infinito.
    ///
    /// - Parameters:
    ///   - page: Numero de pagina a cargar.
    ///   - per: Cantidad de mangas por pagina. Por defecto `10`.
    ///
    /// - Note: Si ya hay una carga en curso (`isLoading == true`), la llamada se ignora.
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

    /// Aplica los filtros combinados y actualiza la lista de mangas.
    ///
    /// Este metodo analiza el estado actual de ``filters`` y decide automaticamente
    /// que endpoint usar:
    ///
    /// - Si hay filtros avanzados (anio, score): usa **Jikan API**
    /// - Si hay multiples categorias: usa **POST /search/manga**
    /// - Si hay una sola categoria: usa el endpoint especifico
    /// - Sin filtros: carga todos los mangas
    ///
    /// - Parameters:
    ///   - page: Numero de pagina a obtener. Por defecto `1`.
    ///   - per: Cantidad de mangas por pagina. Por defecto `10`.
    ///
    /// ## Ejemplo
    ///
    /// ```swift
    /// viewModel.filters.genres = ["Action", "Adventure"]
    /// viewModel.filters.minScore = 8.0
    /// await viewModel.applyFilters()
    /// ```
    func applyFilters(page: Int = 1, per: Int = 10) async {
        isLoading = true
        errorMessage = nil

        do {
            // Si hay filtros avanzados (año, score), usar Jikan API
            if filters.hasAdvancedFilters {
                try await applyJikanFilters(page: page, limit: per)
            }
            // Si SOLO hay una demografía (sin géneros ni temas), usar endpoint específico
            else if filters.demographics.count == 1 && filters.genres.isEmpty && filters.themes.isEmpty {
                let response = try await repository.getMangasByDemographic(filters.demographics.first!, page: page, per: per)
                mangas = response.items
                metadata = response.metadata
            }
            // Si SOLO hay un género (sin demografías ni temas), usar endpoint específico
            else if filters.genres.count == 1 && filters.demographics.isEmpty && filters.themes.isEmpty {
                let response = try await repository.getMangasByGenre(filters.genres.first!, page: page, per: per)
                mangas = response.items
                metadata = response.metadata
            }
            // Si SOLO hay un tema (sin demografías ni géneros), usar endpoint específico
            else if filters.themes.count == 1 && filters.demographics.isEmpty && filters.genres.isEmpty {
                let response = try await repository.getMangasByTheme(filters.themes.first!, page: page, per: per)
                mangas = response.items
                metadata = response.metadata
            }
            // Si hay filtros múltiples, usar POST /search/manga
            else if !filters.genres.isEmpty || !filters.demographics.isEmpty || !filters.themes.isEmpty {
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

    /// Aplica filtros avanzados usando Jikan API.
    ///
    /// Jikan API permite filtrar por criterios no disponibles en Academy API:
    /// anio de publicacion, puntuacion minima/maxima y estado de publicacion.
    ///
    /// - Parameters:
    ///   - page: Numero de pagina a obtener. Por defecto `1`.
    ///   - limit: Cantidad de mangas por pagina. Por defecto `25`.
    ///
    /// - Throws: Error de red si la llamada a Jikan falla.
    private func applyJikanFilters(page: Int = 1, limit: Int = 25) async throws {
        let response = try await repository.searchMangasJikan(
            query: filters.searchText.isEmpty ? nil : filters.searchText,
            genres: nil as [Int]?,
            minScore: filters.minScore,
            maxScore: nil as Double?,
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

    /// Convierte ``SortOption`` al parametro `orderBy` de Jikan API.
    private var jikanOrderBy: String {
        switch filters.sortBy {
        case .score: return "score"
        case .title: return "title"
        case .recent: return "start_date"
        }
    }

    /// Determina el orden ascendente/descendente para Jikan API.
    private var jikanSortOrder: String {
        switch filters.sortBy {
        case .score, .recent: return "desc"
        case .title: return "asc"
        }
    }

    /// Ordena los mangas localmente segun el criterio seleccionado.
    ///
    /// - Parameter option: Criterio de ordenamiento a aplicar.
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
