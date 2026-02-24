//
//  ViewState.swift
//  MisMangas
//
//  Created by Juan Carlos on 23/2/26.
//

import Foundation

/// Estados posibles de una vista que carga datos.
///
/// Usar este enum en lugar de variables separadas (`isLoading`, `errorMessage`)
/// garantiza que solo haya un estado activo a la vez, evitando inconsistencias.
///
/// ## Ejemplo de uso en ViewModel
///
/// ```swift
/// @Observable
/// final class MyViewModel {
///     var state: ViewState = .idle
///
///     func loadData() async {
///         state = .loading
///         do {
///             let data = try await repository.getData()
///             state = data.isEmpty ? .empty : .loaded
///         } catch {
///             state = .error(error.localizedDescription)
///         }
///     }
/// }
/// ```
///
/// ## Ejemplo de uso en View
///
/// ```swift
/// var body: some View {
///     switch viewModel.state {
///     case .idle, .loading:
///         ProgressView()
///     case .loaded:
///         ContentView()
///     case .empty:
///         EmptyStateView()
///     case .error(let message):
///         ErrorView(message: message)
///     }
/// }
/// ```
enum ViewState: Equatable {
    /// Estado inicial, antes de cargar datos.
    case idle

    /// Cargando datos.
    case loading

    /// Datos cargados correctamente.
    case loaded

    /// Carga completada pero sin datos.
    case empty

    /// Error con mensaje descriptivo.
    case error(String)

    /// Indica si está en proceso de carga.
    var isLoading: Bool {
        self == .loading
    }

    /// Mensaje de error si existe.
    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
}
