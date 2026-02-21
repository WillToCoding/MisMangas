//
//  CloudCollectionViewModel.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import Foundation
import SwiftData
#if os(iOS)
import WidgetKit
#endif

/// ViewModel para gestionar la coleccion de mangas del usuario en la nube.
///
/// `CloudCollectionViewModel` sincroniza la coleccion del usuario con la API REST,
/// permitiendo agregar, eliminar y consultar mangas de la coleccion.
///
/// Requiere un ``AuthViewModel`` autenticado para funcionar, ya que todas las
/// operaciones necesitan el token JWT del usuario.
///
/// ## Ejemplo de uso
///
/// ```swift
/// let authVM = AuthViewModel()
/// let cloudVM = CloudCollectionViewModel(authVM: authVM)
///
/// // Cargar coleccion
/// await cloudVM.loadCollection()
///
/// // Agregar manga
/// try await cloudVM.addToCollection(
///     manga: manga,
///     volumesOwned: [1, 2, 3],
///     readingVolume: 2,
///     completeCollection: false
/// )
///
/// // Verificar si un manga esta en la coleccion
/// if cloudVM.isInCollection(manga.id) {
///     print("Ya lo tienes!")
/// }
/// ```
@MainActor
@Observable
final class CloudCollectionViewModel {
    /// Coleccion de mangas del usuario sincronizada con la nube.
    var cloudCollection: [UserMangaCollection] = []

    /// Indica si hay una operacion de sincronizacion en curso.
    var isLoading = false

    /// Mensaje de error de la ultima operacion fallida.
    var errorMessage: String?

    private let repository = Network()
    private let authVM: AuthViewModel
    #if os(iOS)
    private var modelContainer: ModelContainer?
    #endif

    /// Crea una nueva instancia del ViewModel.
    ///
    /// - Parameter authVM: ViewModel de autenticacion para obtener el token.
    init(authVM: AuthViewModel) {
        self.authVM = authVM
    }

    #if os(iOS)
    /// Configura el ModelContainer para sincronización local
    func setModelContainer(_ container: ModelContainer) {
        self.modelContainer = container
    }
    #endif

    // MARK: - Load Collection

    /// Carga la coleccion completa del usuario desde la API.
    ///
    /// Obtiene todos los mangas de la coleccion del usuario autenticado.
    /// La respuesta **no esta paginada**, se obtiene todo en una sola llamada.
    ///
    /// Si detecta un error 401 (no autorizado), cierra la sesion automaticamente.
    func loadCollection() async {
        guard let token = authVM.authToken else {
            errorMessage = "No estás autenticado"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            cloudCollection = try await repository.getUserCollection(token: token)
            print("Colección cloud cargada: \(cloudCollection.count) mangas")

            // Sincronizar a local (SwiftData) - solo iOS
            #if os(iOS)
            await syncToLocal()

            // Actualizar datos del widget
            await SharedData.shared.updateWidgetFromCollection(
                cloudCollection,
                userEmail: authVM.userEmail
            )
            #endif
        } catch {
            if isUnauthorizedError(error) {
                authVM.handleSessionExpired()
            } else {
                errorMessage = "Error al cargar colección: \(error.localizedDescription)"
                print("Error cargando colección cloud: \(error)")
            }
        }

        isLoading = false
    }

    #if os(iOS)
    /// Sincroniza la colección cloud a SwiftData local
    private func syncToLocal() async {
        guard let container = modelContainer else {
            print("ModelContainer no configurado, saltando sincronización local")
            return
        }

        let dataContainer = DataContainer(modelContainer: container)
        do {
            try await dataContainer.syncAllFromCloud(cloudCollection)
            print("Colección sincronizada a local: \(cloudCollection.count) mangas")
        } catch {
            print("Error sincronizando a local: \(error)")
        }
    }
    #endif

    // MARK: - Add to Collection

    /// Agrega un manga a la coleccion en la nube.
    ///
    /// Si el manga ya existe en la coleccion, se actualizan sus datos.
    /// Despues de agregar, se recarga la coleccion para mantener sincronizado el estado.
    ///
    /// - Parameters:
    ///   - manga: Manga a agregar a la coleccion.
    ///   - volumesOwned: Array con los numeros de tomos que posee el usuario.
    ///   - readingVolume: Numero del tomo por el que va leyendo. `nil` si no ha empezado.
    ///   - completeCollection: `true` si el usuario tiene todos los tomos publicados.
    ///
    /// - Throws: ``AuthError/noToken`` si no hay sesion activa.
    /// - Throws: ``AuthError/tokenExpired`` si el token ha expirado.
    func addToCollection(
        manga: Manga,
        volumesOwned: [Int],
        readingVolume: Int?,
        completeCollection: Bool
    ) async throws {
        guard let token = authVM.authToken else {
            throw AuthError.noToken
        }

        let request = UserMangaCollectionRequest(
            manga: manga.id,
            completeCollection: completeCollection,
            volumesOwned: volumesOwned,
            readingVolume: readingVolume
        )

        do {
            try await repository.addToCollection(request, token: token)
            print("Manga añadido a colección cloud: \(manga.title)")

            // Actualizar fecha de última modificación
            #if os(iOS)
            SharedData.shared.updateMangaDate(manga.id)
            #endif

            // Recargar la colección
            await loadCollection()
        } catch {
            if isUnauthorizedError(error) {
                authVM.handleSessionExpired()
                throw AuthError.tokenExpired
            } else {
                errorMessage = "Error al añadir manga: \(error.localizedDescription)"
                throw error
            }
        }
    }

    // MARK: - Remove from Collection

    /// Elimina un manga de la coleccion en la nube.
    ///
    /// Elimina el manga tanto del servidor como de la lista local.
    /// Tambien actualiza los datos del widget si aplica.
    ///
    /// - Parameter mangaId: ID del manga a eliminar.
    ///
    /// - Throws: ``AuthError/noToken`` si no hay sesion activa.
    /// - Throws: ``AuthError/tokenExpired`` si el token ha expirado.
    func removeFromCollection(mangaId: Int) async throws {
        guard let token = authVM.authToken else {
            throw AuthError.noToken
        }

        do {
            try await repository.deleteFromCollection(mangaId: mangaId, token: token)
            print("Manga eliminado de colección cloud: \(mangaId)")

            // Eliminar localmente también
            cloudCollection.removeAll { $0.manga.id == mangaId }

            // Actualizar datos del widget
            #if os(iOS)
            await SharedData.shared.updateWidgetFromCollection(
                cloudCollection,
                userEmail: authVM.userEmail
            )
            #endif
        } catch {
            if isUnauthorizedError(error) {
                authVM.handleSessionExpired()
                throw AuthError.tokenExpired
            } else {
                errorMessage = "Error al eliminar manga: \(error.localizedDescription)"
                throw error
            }
        }
    }

    // MARK: - Helpers

    /// Verifica si un manga esta en la coleccion del usuario.
    ///
    /// - Parameter mangaId: ID del manga a verificar.
    /// - Returns: `true` si el manga esta en la coleccion, `false` en caso contrario.
    func isInCollection(_ mangaId: Int) -> Bool {
        cloudCollection.contains { $0.manga.id == mangaId }
    }

    /// Obtiene la informacion completa de un manga en la coleccion.
    ///
    /// - Parameter mangaId: ID del manga a buscar.
    /// - Returns: El ``UserMangaCollection`` si existe, `nil` si no esta en la coleccion.
    func getMangaCollection(_ mangaId: Int) -> UserMangaCollection? {
        cloudCollection.first { $0.manga.id == mangaId }
    }

    /// Limpia la coleccion local.
    ///
    /// Llamar este metodo al hacer logout para limpiar los datos del usuario anterior.
    func clearCollection() {
        cloudCollection.removeAll()
        errorMessage = nil
    }

    // MARK: - Private Helpers

    /// Detecta si un error corresponde a una respuesta HTTP 401 (no autorizado).
    ///
    /// - Parameter error: Error a analizar.
    /// - Returns: `true` si el error indica falta de autorizacion.
    private func isUnauthorizedError(_ error: Error) -> Bool {
        // Verificar si es un URLError o si contiene información de HTTP status
        let nsError = error as NSError

        // Verificar si el error contiene un código 401 en su descripción
        let errorDescription = error.localizedDescription.lowercased()
        if errorDescription.contains("401") || errorDescription.contains("unauthorized") {
            return true
        }

        // Verificar código de error específico
        if nsError.code == 401 {
            return true
        }

        return false
    }
}
