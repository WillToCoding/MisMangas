//
//  FilterViewModel.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import Foundation

/// ViewModel para cargar las opciones disponibles de filtros.
///
/// `FilterViewModel` obtiene desde la API las listas de generos, demografias
/// y temas disponibles para filtrar mangas.
///
/// ## Ejemplo de uso
///
/// ```swift
/// let filterVM = FilterViewModel()
/// await filterVM.loadFilterOptions()
///
/// // Usar las opciones en un Picker
/// Picker("Genero", selection: $selectedGenre) {
///     ForEach(filterVM.availableGenres, id: \.self) { genre in
///         Text(genre)
///     }
/// }
/// ```
@MainActor
@Observable
final class FilterViewModel {
    /// Lista de generos disponibles (ej: "Action", "Romance").
    var availableGenres: [String] = []

    /// Lista de demografias disponibles (ej: "Shounen", "Seinen").
    var availableDemographics: [String] = []

    /// Lista de temas disponibles (ej: "School", "Mecha").
    var availableThemes: [String] = []

    /// Estado actual de la vista.
    var state: ViewState = .idle

    private let repository: NetworkRepository

    /// Crea una nueva instancia del ViewModel.
    ///
    /// - Parameter repository: Repositorio de red a utilizar. Por defecto usa ``Network``.
    init(repository: NetworkRepository = Network()) {
        self.repository = repository
    }

    /// Carga todas las opciones de filtros desde la API en paralelo.
    ///
    /// Utiliza `async let` para ejecutar las 3 peticiones simultaneamente,
    /// reduciendo el tiempo total de carga.
    ///
    /// Las opciones se cargan una sola vez y se cachean en memoria.
    func loadFilterOptions() async {
        state = .loading

        // Ejecutar las 3 peticiones en paralelo con async let
        async let genres = repository.getGenres()
        async let demographics = repository.getDemographics()
        async let themes = repository.getThemes()

        do {
            // Esperar a que todas terminen
            availableGenres = try await genres
            availableDemographics = try await demographics
            availableThemes = try await themes
            state = .loaded
        } catch {
            state = .error("Error al cargar opciones de filtros: \(error.localizedDescription)")
        }
    }
}
