//
//  CloudCollectionViewModel.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import Foundation
#if os(iOS)
import WidgetKit
#endif

@MainActor
@Observable
final class CloudCollectionViewModel {
    var cloudCollection: [UserMangaCollection] = []
    var isLoading = false
    var errorMessage: String?

    private let repository = NetworkRepository()
    private let authVM: AuthViewModel

    init(authVM: AuthViewModel) {
        self.authVM = authVM
    }

    // MARK: - Load Collection

    /// Carga la colección del usuario desde la nube
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
            } else {
                errorMessage = "Error al cargar colección: \(error.localizedDescription)"
                print("Error cargando colección cloud: \(error)")
            }
        }

        isLoading = false
    }

    // MARK: - Add to Collection

    /// Añade un manga a la colección en la nube
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

    /// Elimina un manga de la colección en la nube
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

    /// Verifica si un manga está en la colección cloud
    func isInCollection(_ mangaId: Int) -> Bool {
        cloudCollection.contains { $0.manga.id == mangaId }
    }

    /// Obtiene la información de un manga de la colección
    func getMangaCollection(_ mangaId: Int) -> UserMangaCollection? {
        cloudCollection.first { $0.manga.id == mangaId }
    }

    /// Limpia la colección (al hacer logout)
    func clearCollection() {
        cloudCollection.removeAll()
        errorMessage = nil
    }

    // MARK: - Private Helpers

    /// Detecta si un error es de autorización (401)
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
