//
//  MangaCoverVM.swift
//  MisMangas
//
//  Created by Juan Carlos on 1/2/26.
//

import SwiftUI

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import NetworkAPI
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

/// ViewModel para cargar y cachear imagenes de portadas de manga.
///
/// `MangaCoverVM` gestiona la carga asincrona de imagenes con cache en disco.
/// Soporta todas las plataformas Apple usando `PlatformImage` como alias.
///
/// ## Ejemplo de uso
///
/// ```swift
/// struct MangaRow: View {
///     @State private var coverVM = MangaCoverVM()
///
///     var body: some View {
///         Image(uiImage: coverVM.image ?? UIImage())
///             .onAppear {
///                 coverVM.getImage(url: manga.coverURL)
///             }
///     }
/// }
/// ```
///
/// ## Plataformas
///
/// | Plataforma | Tipo de imagen |
/// |------------|----------------|
/// | iOS, tvOS, watchOS, visionOS | `UIImage` |
/// | macOS | `NSImage` |
@Observable @MainActor
final class MangaCoverVM {
    /// Imagen cargada, `nil` si no se ha cargado o hubo error.
    var image: PlatformImage?

    /// Indica si hay una descarga en curso.
    var isLoading = false

    /// Carga una imagen desde URL con cache en disco.
    ///
    /// El metodo verifica primero si la imagen existe en cache local.
    /// Si no existe, la descarga y guarda en disco para uso futuro.
    ///
    /// - Parameter url: URL de la imagen a cargar. Si es `nil`, no hace nada.
    ///
    /// - Note: Las llamadas concurrentes con `isLoading == true` se ignoran.
    func getImage(url: URL?) {
        guard let url else { return }

        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        // Verificar si ya está en caché de disco
        let file = ImageDownloader.shared.getFileURL(url: url)
        if FileManager.default.fileExists(atPath: file.path()) {
            do {
                let data = try Data(contentsOf: file)
                image = PlatformImage(data: data)
                return
            } catch {
                print("Error loading cached image: \(error)")
            }
        }

        // Si no está en caché, descargar
        guard !isLoading else { return }
        isLoading = true

        Task {
            do {
                image = try await ImageDownloader.shared.image(for: url)
            } catch {
                print("Error downloading image: \(error)")
            }
            isLoading = false
        }
        #elseif os(macOS)
        // macOS: descargar directamente (NSImage)
        guard !isLoading else { return }
        isLoading = true

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                image = PlatformImage(data: data)
            } catch {
                print("Error downloading image: \(error)")
            }
            isLoading = false
        }
        #endif
    }
}
