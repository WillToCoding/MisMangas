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

/// ViewModel para la gestion de autenticacion de usuarios.
///
/// `AuthViewModel` maneja el flujo completo de autenticacion incluyendo:
/// registro, login, renovacion de token y cierre de sesion.
///
/// El token se almacena de forma segura en el **Keychain** del dispositivo,
/// permitiendo sincronizacion via iCloud Keychain entre dispositivos del usuario.
///
/// ## Flujo de autenticacion
///
/// 1. El usuario se registra con ``register(email:password:)``
/// 2. Despues del registro, se hace login automatico
/// 3. El token tiene validez de **2 dias**
/// 4. Al iniciar la app, se verifica y renueva el token si es necesario
///
/// ## Ejemplo de uso
///
/// ```swift
/// let authVM = AuthViewModel()
///
/// // Registro
/// try await authVM.register(email: "user@email.com", password: "12345678")
///
/// // Login
/// try await authVM.login(email: "user@email.com", password: "12345678")
///
/// // Verificar estado
/// if authVM.isAuthenticated {
///     print("Usuario: \(authVM.userEmail ?? "")")
/// }
/// ```
@MainActor
@Observable
final class AuthViewModel {
    /// Indica si el usuario esta autenticado actualmente.
    var isAuthenticated = false

    /// Token JWT actual para las peticiones autenticadas.
    var authToken: String?

    /// Email del usuario autenticado.
    var userEmail: String?

    /// Indica si hay una operacion de autenticacion en curso.
    var isLoading = false

    /// Mensaje de error de la ultima operacion fallida.
    var errorMessage: String?

    /// Indica si se debe mostrar alerta de sesion expirada.
    var showSessionExpiredAlert = false

    private let keychain = KeychainHelper()
    private let repository = Network()

    /// Crea una nueva instancia e intenta restaurar la sesion guardada.
    init() {
        loadSavedSession()
    }

    // MARK: - Session Management

    /// Carga la sesion guardada del Keychain si existe.
    ///
    /// Este metodo se llama automaticamente al inicializar el ViewModel.
    /// Si encuentra un token valido en Keychain, restaura la sesion sin
    /// necesidad de que el usuario vuelva a hacer login.
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

    /// Registra un nuevo usuario en el sistema.
    ///
    /// Despues de un registro exitoso, se realiza login automatico
    /// para que el usuario no tenga que introducir sus credenciales de nuevo.
    ///
    /// - Parameters:
    ///   - email: Email del usuario. Debe tener formato valido.
    ///   - password: Contrasena del usuario. Minimo 8 caracteres.
    ///
    /// - Throws: ``AuthError/invalidEmail`` si el email no es valido.
    /// - Throws: ``AuthError/passwordTooShort`` si la contrasena tiene menos de 8 caracteres.
    /// - Throws: ``AuthError/registrationFailed(_:)`` si el servidor rechaza el registro.
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

    /// Inicia sesion con email y contrasena.
    ///
    /// Al hacer login exitoso:
    /// 1. Se guarda el token en Keychain
    /// 2. Se guarda el email para mostrar al usuario
    /// 3. Se guarda la fecha del token para control de renovacion
    ///
    /// - Parameters:
    ///   - email: Email del usuario registrado.
    ///   - password: Contrasena del usuario.
    ///
    /// - Throws: ``AuthError/loginFailed(_:)`` si las credenciales son incorrectas.
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

    /// Renueva el token de autenticacion.
    ///
    /// Envia el token actual al servidor para obtener uno nuevo.
    /// Si el token actual ya expiro, se cierra la sesion automaticamente.
    ///
    /// - Throws: ``AuthError/noToken`` si no hay token actual.
    /// - Throws: ``AuthError/tokenExpired`` si el token actual ya no es valido.
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

    /// Verifica si el token necesita renovarse y lo renueva automaticamente.
    ///
    /// El token tiene validez de 2 dias. Este metodo verifica la fecha de creacion
    /// y renueva el token si ha pasado mas de 2 dias desde su emision.
    ///
    /// Llamar a este metodo al inicio de la app para mantener la sesion activa.
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

    /// Cierra la sesion del usuario.
    ///
    /// Elimina todos los datos del Keychain (token, email, fecha) y
    /// resetea el estado del ViewModel. Tambien limpia los datos del widget.
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

    /// Maneja una sesion expirada detectada por error 401.
    ///
    /// Cierra la sesion automaticamente y muestra una alerta al usuario
    /// indicando que debe volver a iniciar sesion.
    func handleSessionExpired() {
        print("Sesión expirada detectada. Cerrando sesión...")
        logout()
        showSessionExpiredAlert = true
    }

    // MARK: - Validation

    /// Valida que el email tenga formato correcto usando expresion regular.
    ///
    /// - Parameter email: Email a validar.
    /// - Returns: `true` si el formato es valido, `false` en caso contrario.
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
}
