//
//  AuthViewModel.swift
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
final class AuthViewModel {
    var isAuthenticated = false
    var authToken: String?
    var userEmail: String?

    var isLoading = false
    var errorMessage: String?
    var showSessionExpiredAlert = false

    private let keychain = KeychainHelper()
    private let repository = NetworkRepository()

    init() {
        // Intentar cargar sesión guardada al iniciar
        loadSavedSession()
    }

    // MARK: - Session Management

    /// Carga la sesión guardada del Keychain (si existe)
    func loadSavedSession() {
        if let token = keychain.getToken() {
            authToken = token
            userEmail = keychain.getEmail()
            isAuthenticated = true
            print("Sesion restaurada desde Keychain (iCloud Keychain sync)")
        } else {
            print("No hay sesion guardada")
        }
    }

    // MARK: - Registration

    /// Registra un nuevo usuario
    func register(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil

        // Validaciones
        guard isValidEmail(email) else {
            isLoading = false
            throw AuthError.invalidEmail
        }

        guard password.count >= 8 else {
            isLoading = false
            throw AuthError.passwordTooShort
        }

        do {
            let users = Users(email: email, password: password)
            try await repository.registerUser(users)

            // Después del registro exitoso, hacer login automáticamente
            try await login(email: email, password: password)
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw AuthError.registrationFailed(error.localizedDescription)
        }

        isLoading = false
    }

    // MARK: - Login

    /// Inicia sesión con email y contraseña
    func login(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            let token = try await repository.login(email: email, password: password)

            // Guardar en Keychain
            keychain.saveToken(token)
            keychain.saveEmail(email)
            keychain.saveTokenDate(Date()) // Guardar fecha de creación del token

            // Actualizar estado
            authToken = token
            userEmail = email
            isAuthenticated = true

            print("Login exitoso para: \(email)")
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw AuthError.loginFailed(error.localizedDescription)
        }

        isLoading = false
    }

    // MARK: - Token Renewal

    /// Renueva el token de autenticación
    func renewToken() async throws {
        guard let currentToken = authToken else {
            throw AuthError.noToken
        }

        do {
            let newToken = try await repository.renewToken(currentToken)

            // Guardar el nuevo token y fecha
            keychain.saveToken(newToken)
            keychain.saveTokenDate(Date()) // Actualizar fecha de renovación
            authToken = newToken

            print("Token renovado exitosamente")
        } catch {
            // Si falla la renovación, probablemente el token expiró
            logout()
            throw AuthError.tokenExpired
        }
    }

    /// Verifica si el token necesita renovarse y lo renueva automáticamente
    func checkAndRenewTokenIfNeeded() async {
        guard isAuthenticated else { return }

        if keychain.shouldRenewToken() {
            print("Token necesita renovación (más de 2 días). Renovando...")
            do {
                try await renewToken()
                print("Token renovado automáticamente")
            } catch {
                print("Error al renovar token automáticamente: \(error.localizedDescription)")
                // Si falla, el logout() ya se llamó en renewToken()
            }
        } else {
            if let tokenDate = keychain.getTokenDate() {
                let daysSince = Calendar.current.dateComponents([.day], from: tokenDate, to: Date()).day ?? 0
                print("Token vigente (creado hace \(daysSince) días)")
            }
        }
    }

    // MARK: - Logout

    /// Cierra la sesión del usuario
    func logout() {
        keychain.clearAll()
        authToken = nil
        userEmail = nil
        isAuthenticated = false
        errorMessage = nil
        showSessionExpiredAlert = false

        // Limpiar datos del widget
        #if os(iOS)
        SharedData.shared.clearWidgetData()
        #endif

        print("Sesión cerrada")
    }

    /// Maneja una sesión expirada (error 401)
    func handleSessionExpired() {
        print("Sesión expirada detectada. Cerrando sesión...")
        logout()
        showSessionExpiredAlert = true
    }

    // MARK: - Validation

    /// Valida que el email tenga formato correcto
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
}
