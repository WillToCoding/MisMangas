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

    /// Estado actual de la vista.
    var state: ViewState = .idle

    #if os(iOS) || os(macOS)
    /// ViewModel de sincronización local/cloud
    private(set) var syncVM: SyncViewModel

    /// Conflictos detectados (delegado a SyncViewModel)
    var syncConflicts: [SyncConflict] { syncVM.conflicts }

    /// Indica si hay conflictos pendientes de resolver
    var hasConflicts: Bool { syncVM.hasConflicts }
    #endif

    private let repository: NetworkRepository
    private let authVM: AuthViewModel

    /// Crea una nueva instancia del ViewModel.
    ///
    /// - Parameters:
    ///   - authVM: ViewModel de autenticacion para obtener el token.
    ///   - repository: Repositorio de red. Por defecto usa `Network`.
    init(authVM: AuthViewModel, repository: NetworkRepository = Network()) {
        self.authVM = authVM
        self.repository = repository
        #if os(iOS) || os(macOS)
        self.syncVM = SyncViewModel(repository: repository, authVM: authVM)
        #endif
    }

    #if os(iOS) || os(macOS)
    /// Configura el ModelContainer para sincronización local
    func setModelContainer(_ container: ModelContainer) {
        syncVM.setModelContainer(container)
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
            state = .error("No estás autenticado")
            return
        }

        state = .loading

        do {
            cloudCollection = try await repository.getUserCollection(token: token)
            print("Colección cloud cargada: \(cloudCollection.count) mangas")

            // Sincronizar a local (SwiftData)
            #if os(iOS) || os(macOS)
            await syncVM.syncToLocal(cloudCollection)
            #endif

            // Actualizar datos del widget (solo iOS)
            #if os(iOS)
            await SharedData.shared.updateWidgetFromCollection(
                cloudCollection,
                userEmail: authVM.userEmail
            )
            #endif

            state = cloudCollection.isEmpty ? .empty : .loaded
        } catch {
            if isUnauthorizedError(error) {
                authVM.handleSessionExpired()
            } else {
                state = .error("Error al cargar colección: \(error.localizedDescription)")
                print("Error cargando colección cloud: \(error)")
            }
        }
    }

    // MARK: - Sync Local to Cloud

    #if os(iOS) || os(macOS)
    /// Sincroniza la colección local de SwiftData a la nube.
    ///
    /// Útil después del primer login para migrar mangas guardados localmente
    /// antes de que el usuario tuviera cuenta.
    ///
    /// - Parameter localItems: Items de la colección local a sincronizar.
    func syncLocalCollectionToCloud(_ localItems: [UserCollection]) async {
        await syncVM.syncLocalToCloud(localItems)
        await loadCollection()
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
                state = .error("Error al añadir manga: \(error.localizedDescription)")
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
                state = .error("Error al eliminar manga: \(error.localizedDescription)")
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
        #if os(iOS) || os(macOS)
        syncVM.clearConflicts()
        #endif
        state = .idle
    }

    // MARK: - Conflict Resolution

    #if os(iOS) || os(macOS)
    /// Resuelve un conflicto manteniendo la version local (sube a cloud)
    func resolveConflictKeepLocal(_ conflict: SyncConflict) async {
        await syncVM.resolveConflictKeepLocal(conflict)
        await loadCollection()
    }

    /// Resuelve un conflicto usando la version del cloud (sobrescribe local)
    func resolveConflictUseCloud(_ conflict: SyncConflict) async {
        guard let cloudItem = cloudCollection.first(where: { $0.manga.id == conflict.mangaId }) else {
            print("Item cloud no encontrado para conflicto")
            return
        }
        await syncVM.resolveConflictUseCloud(conflict, cloudItem: cloudItem)
    }
    #endif

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
