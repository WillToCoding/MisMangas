//
//  AuthViewModel+ProfileImage.swift
//  MisMangas
//
//  Created by Juan Carlos on 26/2/26.
//

import Foundation
#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Profile Image Management

extension AuthViewModel {

    #if os(iOS) || os(visionOS)
    /// Carga la imagen de perfil guardada para el usuario actual.
    func loadProfileImage() {
        guard let email = userEmail else { return }
        userProfileImage = profileImageStorage.loadImage(for: email)
    }

    /// Guarda una nueva imagen de perfil.
    ///
    /// La imagen se redimensiona automáticamente si es mayor a 400px de ancho.
    ///
    /// - Parameter image: Imagen a guardar como foto de perfil.
    func saveProfileImage(_ image: UIImage) async {
        guard let email = userEmail else { return }
        await profileImageStorage.saveImage(image, for: email)
        userProfileImage = profileImageStorage.loadImage(for: email)
    }

    /// Elimina la imagen de perfil del usuario actual.
    func deleteProfileImage() {
        guard let email = userEmail else { return }
        profileImageStorage.deleteImage(for: email)
        userProfileImage = nil
    }

    #elseif os(macOS)
    /// Carga la imagen de perfil guardada para el usuario actual.
    func loadProfileImage() {
        guard let email = userEmail else { return }
        userProfileImage = profileImageStorage.loadImage(for: email)
    }

    /// Guarda una nueva imagen de perfil.
    func saveProfileImage(_ image: NSImage) async {
        guard let email = userEmail else { return }
        await profileImageStorage.saveImage(image, for: email)
        userProfileImage = profileImageStorage.loadImage(for: email)
    }

    /// Elimina la imagen de perfil del usuario actual.
    func deleteProfileImage() {
        guard let email = userEmail else { return }
        profileImageStorage.deleteImage(for: email)
        userProfileImage = nil
    }

    #elseif os(tvOS)
    /// Carga el avatar guardado para el usuario actual.
    func loadAvatar() {
        guard let email = userEmail else { return }
        userAvatar = avatarStorage.loadAvatar(for: email)
    }

    /// Guarda el avatar seleccionado.
    ///
    /// - Parameter avatar: Avatar a guardar.
    func saveAvatar(_ avatar: Avatar) {
        guard let email = userEmail else { return }
        avatarStorage.saveAvatar(avatar, for: email)
        userAvatar = avatar
    }

    /// Elimina el avatar del usuario actual.
    func deleteAvatar() {
        guard let email = userEmail else { return }
        avatarStorage.deleteAvatar(for: email)
        userAvatar = nil
    }
    #endif
}
