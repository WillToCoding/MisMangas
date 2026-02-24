//
//  ProfileImageStorage.swift
//  MisMangas
//
//  Created by Juan Carlos on 22/02/26.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Maneja la persistencia de la foto de perfil del usuario.
///
/// La imagen se guarda en el directorio de documentos de la app
/// con redimensionamiento automático para optimizar el almacenamiento.
@MainActor
final class ProfileImageStorage {
    /// Ancho máximo para la foto de perfil (en puntos)
    private let maxImageWidth: CGFloat = 400

    /// Nombre del archivo de la foto de perfil
    private let fileName = "profile_image.jpg"

    /// Calidad de compresión JPEG (0.0 - 1.0)
    private let compressionQuality: CGFloat = 0.8

    private var imageURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(fileName)
    }

    init() {}

    #if canImport(UIKit)
    /// Guarda la imagen de perfil redimensionándola si es necesario.
    ///
    /// - Parameter image: Imagen a guardar
    /// - Returns: `true` si se guardó correctamente, `false` en caso de error
    @discardableResult
    func saveImage(_ image: UIImage) async -> Bool {
        guard let url = imageURL else { return false }

        // Redimensionar si es mayor al ancho máximo
        let resizedImage: UIImage
        #if os(watchOS)
        resizedImage = image
        #else
        if image.size.width > maxImageWidth {
            resizedImage = await image.resize(width: maxImageWidth) ?? image
        } else {
            resizedImage = image
        }
        #endif

        // Comprimir y guardar como JPEG
        guard let data = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            return false
        }

        do {
            try data.write(to: url)
            print("[ProfileImageStorage] Imagen guardada: \(url.lastPathComponent)")
            return true
        } catch {
            print("[ProfileImageStorage] Error guardando imagen: \(error)")
            return false
        }
    }

    /// Carga la imagen de perfil guardada.
    ///
    /// - Returns: La imagen de perfil o `nil` si no existe
    func loadImage() -> UIImage? {
        guard let url = imageURL,
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
    #endif

    /// Elimina la imagen de perfil guardada.
    func deleteImage() {
        guard let url = imageURL else { return }
        try? FileManager.default.removeItem(at: url)
        print("[ProfileImageStorage] Imagen eliminada")
    }

    /// Verifica si existe una imagen de perfil guardada.
    var hasImage: Bool {
        guard let url = imageURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
}

// MARK: - UIImage Extension
#if canImport(UIKit) && !os(watchOS)
extension UIImage {
    /// Redimensiona la imagen manteniendo el aspect ratio.
    func resize(width: CGFloat) async -> UIImage? {
        let scale = min(1, width / size.width)
        let newSize = CGSize(width: width, height: size.height * scale)
        return await byPreparingThumbnail(ofSize: newSize)
    }
}
#endif
