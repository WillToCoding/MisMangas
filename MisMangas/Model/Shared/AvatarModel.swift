//
//  AvatarModel.swift
//  MisMangas
//
//  Created by Juan Carlos on 25/2/26.
//

import Foundation
import SwiftUI

/// Modelo para los avatares predefinidos disponibles en la app.
///
/// Los avatares se cargan desde SharedAssets.xcassets/Avatars/
enum Avatar: String, CaseIterable, Identifiable {
    case alaDeAguila
    case armadura
    case cronos
    case eclipse
    case eco
    case elementa
    case fenix
    case geo
    case giro
    case luzEstelar
    case psique
    case pulso
    case reflejo
    case roca
    case sirena
    case sombra
    case telemente
    case tempestad
    case titan
    case vortex

    var id: String { rawValue }

    /// Nombre del asset en SharedAssets.xcassets
    var assetName: String {
        rawValue
    }

    /// Nombre para mostrar al usuario
    var displayName: String {
        switch self {
        case .alaDeAguila: return "Ala de Águila"
        case .armadura: return "Armadura"
        case .cronos: return "Cronos"
        case .eclipse: return "Eclipse"
        case .eco: return "Eco"
        case .elementa: return "Elementa"
        case .fenix: return "Fénix"
        case .geo: return "Geo"
        case .giro: return "Giro"
        case .luzEstelar: return "Luz Estelar"
        case .psique: return "Psique"
        case .pulso: return "Pulso"
        case .reflejo: return "Reflejo"
        case .roca: return "Roca"
        case .sirena: return "Sirena"
        case .sombra: return "Sombra"
        case .telemente: return "Telemente"
        case .tempestad: return "Tempestad"
        case .titan: return "Titán"
        case .vortex: return "Vórtex"
        }
    }

    /// Categoría del avatar
    var category: AvatarCategory {
        switch self {
        case .elementa, .tempestad, .fenix, .geo, .eco:
            return .elementales
        case .eclipse, .luzEstelar, .cronos, .vortex:
            return .cosmicos
        case .armadura, .titan, .alaDeAguila, .roca:
            return .guerreros
        case .psique, .telemente, .sombra, .reflejo:
            return .misticos
        case .sirena, .pulso, .giro:
            return .especiales
        }
    }
}

// MARK: - Avatar Category

enum AvatarCategory: String, CaseIterable, Identifiable {
    case elementales
    case cosmicos
    case guerreros
    case misticos
    case especiales

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .elementales: return "Elementales"
        case .cosmicos: return "Cósmicos"
        case .guerreros: return "Guerreros"
        case .misticos: return "Místicos"
        case .especiales: return "Especiales"
        }
    }

    var icon: String {
        switch self {
        case .elementales: return "flame.fill"
        case .cosmicos: return "sparkles"
        case .guerreros: return "shield.fill"
        case .misticos: return "moon.stars.fill"
        case .especiales: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .elementales: return .orange
        case .cosmicos: return .purple
        case .guerreros: return .red
        case .misticos: return .indigo
        case .especiales: return .teal
        }
    }

    /// Avatares de esta categoría
    var avatars: [Avatar] {
        Avatar.allCases.filter { $0.category == self }
    }
}

// MARK: - Avatar Storage

/// Maneja la persistencia del avatar seleccionado por el usuario.
@MainActor
final class AvatarStorage {
    private let userDefaults = UserDefaults.standard
    private let avatarKey = "selectedAvatar"

    init() {}

    /// Guarda el avatar seleccionado para un usuario.
    func saveAvatar(_ avatar: Avatar, for email: String) {
        let key = "\(avatarKey)_\(email.sanitizedForKey)"
        userDefaults.set(avatar.rawValue, forKey: key)
        print("[AvatarStorage] Avatar guardado: \(avatar.displayName) para \(email)")
    }

    /// Carga el avatar seleccionado de un usuario.
    func loadAvatar(for email: String) -> Avatar? {
        let key = "\(avatarKey)_\(email.sanitizedForKey)"
        guard let rawValue = userDefaults.string(forKey: key),
              let avatar = Avatar(rawValue: rawValue) else {
            return nil
        }
        return avatar
    }

    /// Elimina el avatar guardado de un usuario.
    func deleteAvatar(for email: String) {
        let key = "\(avatarKey)_\(email.sanitizedForKey)"
        userDefaults.removeObject(forKey: key)
    }

    /// Verifica si el usuario tiene un avatar seleccionado.
    func hasAvatar(for email: String) -> Bool {
        loadAvatar(for: email) != nil
    }
}

private extension String {
    var sanitizedForKey: String {
        replacingOccurrences(of: "@", with: "_at_")
            .replacingOccurrences(of: ".", with: "_")
    }
}
