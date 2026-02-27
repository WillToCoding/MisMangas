//
//  SyncViewModel.swift
//  MisMangas
//
//  Created by Juan Carlos on 23/2/26.
//

#if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
import Foundation
import SwiftData

/// ViewModel para sincronización entre colección local (SwiftData) y cloud (API).
///
/// `SyncViewModel` gestiona:
/// - Sincronización de cloud a local
/// - Subida de cambios pendientes locales
/// - Detección y resolución de conflictos
///
/// ## Ejemplo de uso
///
/// ```swift
/// let syncVM = SyncViewModel(repository: Network(), authVM: authVM)
/// syncVM.setModelContainer(container)
///
/// // Sincronizar cloud a local
/// let conflicts = await syncVM.syncToLocal(cloudCollection)
///
/// // Resolver conflicto
/// await syncVM.resolveConflictKeepLocal(conflict)
/// ```
@MainActor
@Observable
final class SyncViewModel {
    /// Conflictos detectados entre local y cloud
    var conflicts: [SyncConflict] = []

    /// Indica si hay conflictos pendientes
    var hasConflicts: Bool { !conflicts.isEmpty }

    /// Estado de la sincronización
    var state: ViewState = .idle

    private let repository: NetworkRepository
    private let authVM: AuthViewModel
    private var modelContainer: ModelContainer?

    /// Crea una nueva instancia del ViewModel.
    ///
    /// - Parameters:
    ///   - repository: Repositorio de red.
    ///   - authVM: ViewModel de autenticación para obtener el token.
    init(repository: NetworkRepository = Network(), authVM: AuthViewModel) {
        self.repository = repository
        self.authVM = authVM
    }

    /// Configura el ModelContainer para operaciones con SwiftData
    func setModelContainer(_ container: ModelContainer) {
        self.modelContainer = container
    }

    // MARK: - Sync Cloud to Local

    /// Sincroniza la colección cloud a SwiftData local.
    ///
    /// Usa estrategia "last-write-wins":
    /// 1. Primero sube los cambios locales pendientes al cloud
    /// 2. Luego sincroniza el cloud a local
    ///
    /// - Parameter cloudCollection: Colección obtenida del servidor.
    /// - Returns: `true` si la sincronización fue exitosa.
    @discardableResult
    func syncToLocal(_ cloudCollection: [UserMangaCollection]) async -> Bool {
        guard let container = modelContainer else {
            print("ModelContainer no configurado, saltando sincronización local")
            return false
        }

        state = .loading
        let dataContainer = DataContainer(modelContainer: container)

        do {
            // 1. Subir cambios pendientes locales (local wins para estos)
            await uploadPendingChanges()

            // 2. Sincronizar cloud a local (cloud wins para el resto)
            try await dataContainer.syncAllFromCloud(cloudCollection)
            print("Colección sincronizada a local: \(cloudCollection.count) mangas")

            state = .loaded
            return true
        } catch {
            print("Error sincronizando a local: \(error)")
            state = .error("Error de sincronización: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Upload Pending Changes

    /// Sube los cambios locales pendientes al cloud.
    ///
    /// Usa estrategia de timestamps:
    /// - Si `lastModified > lastSyncDate` -> el cambio local es mas reciente -> subir
    /// - Si no -> descartar cambio local (cloud probablemente tiene datos mas recientes de otro dispositivo)
    ///
    /// Esto permite:
    /// - Que cambios intencionales (ej: reiniciar lectura) se suban correctamente
    /// - Que dispositivos desactualizados no sobrescriban cambios mas recientes del cloud
    func uploadPendingChanges() async {
        guard let container = modelContainer,
              let token = authVM.authToken else { return }

        let dataContainer = DataContainer(modelContainer: container)

        do {
            let pendingItems = try await dataContainer.getPendingSyncItems()

            for item in pendingItems {
                // Solo subir si el cambio local es mas reciente que la ultima sync
                // Esto evita que un dispositivo desactualizado sobrescriba cambios del cloud
                guard item.hasRecentLocalChanges else {
                    print("[Sync] Descartando cambio antiguo de \(item.mangaTitle) (lastModified <= lastSyncDate)")
                    try await dataContainer.clearPendingSync(mangaId: item.mangaId)
                    continue
                }

                let request = UserMangaCollectionRequest(
                    manga: item.mangaId,
                    completeCollection: item.hasCompleteCollection,
                    volumesOwned: item.volumesOwned,
                    readingVolume: item.currentReadingVolume
                )

                do {
                    try await repository.addToCollection(request, token: token)
                    try await dataContainer.markAsSynced(mangaId: item.mangaId)
                    print("[Sync] Subido a cloud: \(item.mangaTitle)")
                } catch {
                    print("[Sync] Error subiendo \(item.mangaTitle): \(error)")
                }
            }
        } catch {
            print("[Sync] Error obteniendo items pendientes: \(error)")
        }
    }

    // MARK: - Sync Local to Cloud

    /// Sincroniza la colección local completa a la nube.
    ///
    /// Útil después del primer login para migrar mangas guardados localmente
    /// antes de que el usuario tuviera cuenta.
    ///
    /// - Parameter localItems: Items de la colección local a sincronizar.
    func syncLocalToCloud(_ localItems: [UserCollection]) async {
        guard let token = authVM.authToken else {
            print("No hay token para sincronizar")
            return
        }

        guard !localItems.isEmpty else {
            print("No hay mangas locales para sincronizar")
            return
        }

        state = .loading
        print("Sincronizando \(localItems.count) mangas locales a la nube...")

        for item in localItems {
            let request = UserMangaCollectionRequest(
                manga: item.id,
                completeCollection: item.hasCompleteCollection,
                volumesOwned: item.volumesOwned,
                readingVolume: item.currentReadingVolume
            )

            do {
                try await repository.addToCollection(request, token: token)
                print("[Sync] Sincronizado: \(item.title)")
            } catch {
                print("[Sync] Error sincronizando \(item.title): \(error)")
            }
        }

        state = .loaded
    }

    // MARK: - Conflict Resolution

    /// Resuelve un conflicto manteniendo la versión local (sube a cloud).
    ///
    /// - Parameter conflict: Conflicto a resolver.
    func resolveConflictKeepLocal(_ conflict: SyncConflict) async {
        guard let container = modelContainer,
              let token = authVM.authToken else { return }

        let dataContainer = DataContainer(modelContainer: container)

        do {
            let request = UserMangaCollectionRequest(
                manga: conflict.mangaId,
                completeCollection: false,
                volumesOwned: conflict.localVolumesOwned,
                readingVolume: conflict.localReadingVolume
            )

            try await repository.addToCollection(request, token: token)
            try await dataContainer.markAsSynced(mangaId: conflict.mangaId)

            conflicts.removeAll { $0.mangaId == conflict.mangaId }
            print("Conflicto resuelto (local): \(conflict.mangaTitle)")
        } catch {
            print("Error resolviendo conflicto: \(error)")
        }
    }

    /// Resuelve un conflicto usando la versión del cloud (sobrescribe local).
    ///
    /// - Parameters:
    ///   - conflict: Conflicto a resolver.
    ///   - cloudItem: Item del cloud con los datos correctos.
    func resolveConflictUseCloud(_ conflict: SyncConflict, cloudItem: UserMangaCollection) async {
        guard let container = modelContainer else { return }

        let dataContainer = DataContainer(modelContainer: container)

        do {
            try await dataContainer.resolveConflictUseCloud(mangaId: conflict.mangaId, cloudItem: cloudItem)

            conflicts.removeAll { $0.mangaId == conflict.mangaId }
            print("Conflicto resuelto (cloud): \(conflict.mangaTitle)")
        } catch {
            print("Error resolviendo conflicto: \(error)")
        }
    }

    /// Limpia todos los conflictos pendientes.
    func clearConflicts() {
        conflicts.removeAll()
    }
}
#endif
