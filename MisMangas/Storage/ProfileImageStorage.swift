//
//  ProfileImageStorage.swift
//  MisMangas
//
//  Created by Juan Carlos on 22/02/26.
//

import Foundation
import NetworkAPI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Maneja la persistencia de la foto de perfil del usuario.
///
/// La imagen se guarda en el directorio de documentos de la app
/// con redimensionamiento automático para optimizar el almacenamiento.
/// Cada usuario tiene su propia imagen identificada por su email.
@MainActor
final class ProfileImageStorage {
    /// Ancho máximo para la foto de perfil (en puntos)
    private let maxImageWidth: CGFloat = 400

    /// Calidad de compresión JPEG (0.0 - 1.0)
    private let compressionQuality: CGFloat = 0.8

    /// Genera la URL del archivo de imagen para un usuario específico.
    private func imageURL(for email: String) -> URL? {
        let safeEmail = email.replacingOccurrences(of: "@", with: "_at_")
            .replacingOccurrences(of: ".", with: "_")
        let fileName = "profile_\(safeEmail).jpg"
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(fileName)
    }

    init() {}

    #if canImport(UIKit)
    /// Guarda la imagen de perfil redimensionándola si es necesario.
    ///
    /// - Parameters:
    ///   - image: Imagen a guardar
    ///   - email: Email del usuario para identificar la imagen
    /// - Returns: `true` si se guardó correctamente, `false` en caso de error
    @discardableResult
    func saveImage(_ image: UIImage, for email: String) async -> Bool {
        guard let url = imageURL(for: email) else { return false }

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
    /// - Parameter email: Email del usuario
    /// - Returns: La imagen de perfil o `nil` si no existe
    func loadImage(for email: String) -> UIImage? {
        guard let url = imageURL(for: email),
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
    #elseif canImport(AppKit)
    /// Guarda la imagen de perfil redimensionándola si es necesario.
    ///
    /// - Parameters:
    ///   - image: Imagen a guardar
    ///   - email: Email del usuario para identificar la imagen
    @discardableResult
    func saveImage(_ image: NSImage, for email: String) async -> Bool {
        guard let url = imageURL(for: email) else { return false }

        // Redimensionar si es mayor al ancho máximo
        let resizedImage: NSImage
        if image.size.width > maxImageWidth {
            resizedImage = await image.resize(width: maxImageWidth) ?? image
        } else {
            resizedImage = image
        }

        // Convertir a JPEG y guardar
        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality]) else {
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
    /// - Parameter email: Email del usuario
    func loadImage(for email: String) -> NSImage? {
        guard let url = imageURL(for: email),
              FileManager.default.fileExists(atPath: url.path),
              let image = NSImage(contentsOf: url) else {
            return nil
        }
        return image
    }
    #endif

    /// Elimina la imagen de perfil guardada.
    ///
    /// - Parameter email: Email del usuario
    func deleteImage(for email: String) {
        guard let url = imageURL(for: email) else { return }
        try? FileManager.default.removeItem(at: url)
        print("[ProfileImageStorage] Imagen eliminada para: \(email)")
    }

    /// Verifica si existe una imagen de perfil guardada.
    ///
    /// - Parameter email: Email del usuario
    func hasImage(for email: String) -> Bool {
        guard let url = imageURL(for: email) else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
}
