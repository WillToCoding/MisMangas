//
//  AuthError.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import Foundation

enum AuthError: LocalizedError {
    case invalidEmail
    case passwordTooShort
    case passwordsDontMatch
    case noToken
    case tokenExpired
    case registrationFailed(String)
    case loginFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "El email no es válido"
        case .passwordTooShort:
            return "La contraseña debe tener al menos 8 caracteres"
        case .passwordsDontMatch:
            return "Las contraseñas no coinciden"
        case .noToken:
            return "No hay token de autenticación"
        case .tokenExpired:
            return "La sesión ha expirado. Por favor, vuelve a iniciar sesión"
        case .registrationFailed(let message):
            return "Error al registrar: \(message)"
        case .loginFailed(let message):
            return "Error al iniciar sesión: \(message)"
        }
    }
}
