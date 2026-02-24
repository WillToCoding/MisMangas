//
//  HomeViewModel.swift
//  MisMangas
//
//  Created by Juan Carlos on 2/2/26.
//

import Foundation

/// ViewModel para la pantalla principal (Home).
///
/// ## Overview
/// `HomeViewModel` gestiona la carga de datos para la vista Home,
/// incluyendo los mejores mangas y mangas agrupados por demografía.
///
/// Utiliza concurrencia estructurada para cargar múltiples secciones
/// en paralelo, mejorando el rendimiento de la carga inicial.
///
/// ## Ejemplo de uso
/// ```swift
/// @State private var viewModel = HomeViewModel()
///
/// var body: some View {
///     HomeView()
///         .task { await viewModel.loadAll() }
/// }
/// ```
///
/// ## Topics
///
/// ### Datos
/// - ``bestMangas``
/// - ``mangasByDemographic``
///
/// ### Carga
/// - ``loadAll()``
@MainActor
@Observable
final class HomeViewModel {
    /// Los 10 mangas mejor puntuados.
    var bestMangas: [Manga] = []

    /// Mangas agrupados por demografía (Shounen, Seinen, etc.).
    var mangasByDemographic: [String: [Manga]] = [:]

    /// Estado actual de la vista.
    var state: ViewState = .idle

    private let repository: NetworkRepository
    private let demographics = ["Shounen", "Seinen", "Shoujo", "Josei", "Kids"]

    /// Error capturado durante la carga (para mostrar al usuario).
    private var loadingError: String?

    /// Crea una instancia del ViewModel.
    /// - Parameter repository: Repositorio de red para obtener datos. Por defecto usa `Network()`.
    init(repository: NetworkRepository = Network()) {
        self.repository = repository
    }

    /// Carga todos los datos de la Home en paralelo.
    ///
    /// Ejecuta simultáneamente la carga de mejores mangas y mangas por demografía
    /// usando `async let` para maximizar el rendimiento.
    ///
    /// Si hay errores de red pero algunos datos se cargan, muestra los datos disponibles.
    /// Solo muestra error si no hay ningún dato disponible.
    func loadAll() async {
        state = .loading
        loadingError = nil
        bestMangas = []
        mangasByDemographic = [:]

        async let best: () = loadBest()
        async let demos: () = loadDemographics()
        _ = await (best, demos)

        // Verificar si hay datos disponibles
        let hasData = !bestMangas.isEmpty || mangasByDemographic.values.contains { !$0.isEmpty }

        if let error = loadingError, !hasData {
            state = .error(error)
        } else if hasData {
            state = .loaded
        } else {
            state = .empty
        }
    }

    private func loadBest() async {
        do {
            let response = try await repository.getBestMangas(page: 1, per: 10)
            bestMangas = response.items
        } catch {
            if loadingError == nil {
                loadingError = error.localizedDescription
            }
        }
    }

    private func loadDemographics() async {
        await withTaskGroup(of: (String, [Manga], String?).self) { group in
            for demo in demographics {
                group.addTask {
                    do {
                        let response = try await self.repository.getMangasByDemographic(demo, page: 1, per: 10)
                        return (demo, response.items, nil)
                    } catch {
                        return (demo, [], error.localizedDescription)
                    }
                }
            }

            for await (demo, mangas, error) in group {
                mangasByDemographic[demo] = mangas
                if let error = error, loadingError == nil {
                    loadingError = error
                }
            }
        }
    }
}
