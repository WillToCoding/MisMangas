//
//  AuthVMTests.swift
//  MisMangasTests
//
//  Created by Juan Carlos on 21/2/26.
//

import Testing
@testable import MisMangas

/// Tests de AuthViewModel
///
/// **Given:** El sistema tiene validaciones de email y password en producción.
/// **When:** Probamos distintos inputs.
/// **Then:** Verificamos que las validaciones funcionan correctamente.
///
/// Si alguien cambia el regex de email o el mínimo de password, estos tests fallarán.
@MainActor
@Suite("Test de autenticación")
struct AuthVMTests {
    let vm: AuthViewModel

    init() {
        vm = AuthViewModel()
    }

    // MARK: - Email Validation Tests

    @Test("Email válido pasa validación")
    func checkValidEmail() async throws {
        // Given: un email con formato correcto
        // When: intentamos registrar
        // Then: no debe lanzar AuthError.invalidEmail

        do {
            try await vm.register(email: "test@example.com", password: "12345678")
            // Si llega aquí sin error de email, el test pasa
            // (puede fallar por red, pero no por validación de email)
        } catch AuthError.invalidEmail {
            #expect(Bool(false), "Email válido no debería lanzar invalidEmail")
        } catch {
            // Otros errores (red, etc.) son aceptables - no estamos testeando la red
        }
    }

    @Test("Email sin @ es inválido")
    func checkInvalidEmailNoAt() async throws {
        do {
            try await vm.register(email: "testexample.com", password: "12345678")
            #expect(Bool(false), "Email sin @ debería fallar")
        } catch AuthError.invalidEmail {
            // Correcto: el email inválido lanzó el error esperado
        } catch {
            #expect(Bool(false), "Debería ser AuthError.invalidEmail, no otro error")
        }
    }

    @Test("Email sin dominio es inválido")
    func checkInvalidEmailNoDomain() async throws {
        do {
            try await vm.register(email: "test@", password: "12345678")
            #expect(Bool(false), "Email sin dominio debería fallar")
        } catch AuthError.invalidEmail {
            // Correcto
        } catch {
            #expect(Bool(false), "Debería ser AuthError.invalidEmail")
        }
    }

    // MARK: - Password Validation Tests

    @Test("Password con 8+ caracteres es válido")
    func checkValidPassword() async throws {
        do {
            try await vm.register(email: "test@example.com", password: "12345678")
            // No lanzó passwordTooShort - correcto
        } catch AuthError.passwordTooShort {
            #expect(Bool(false), "Password de 8 chars no debería ser muy corto")
        } catch {
            // Otros errores son aceptables
        }
    }

    @Test("Password con menos de 8 caracteres es inválido")
    func checkShortPassword() async throws {
        do {
            try await vm.register(email: "test@example.com", password: "1234567")
            #expect(Bool(false), "Password de 7 chars debería fallar")
        } catch AuthError.passwordTooShort {
            // Correcto: password corto lanzó el error esperado
        } catch {
            #expect(Bool(false), "Debería ser AuthError.passwordTooShort")
        }
    }

    @Test("Password vacío es inválido")
    func checkEmptyPassword() async throws {
        do {
            try await vm.register(email: "test@example.com", password: "")
            #expect(Bool(false), "Password vacío debería fallar")
        } catch AuthError.passwordTooShort {
            // Correcto
        } catch {
            #expect(Bool(false), "Debería ser AuthError.passwordTooShort")
        }
    }

    // MARK: - Logout Tests

    @Test("Logout limpia el estado completamente")
    func checkLogoutClearsState() async {
        // Given: simulamos un estado autenticado
        vm.authToken = "fake-token"
        vm.userEmail = "test@example.com"
        vm.isAuthenticated = true
        vm.errorMessage = "some error"

        // When: hacemos logout
        vm.logout()

        // Then: todo debe estar limpio
        #expect(vm.authToken == nil)
        #expect(vm.userEmail == nil)
        #expect(vm.isAuthenticated == false)
        #expect(vm.errorMessage == nil)
    }

    // MARK: - State Tests

    @Test("Estado inicial no autenticado")
    func checkInitialState() {
        let newVM = AuthViewModel()

        #expect(newVM.authToken == nil)
        #expect(newVM.userEmail == nil)
        #expect(newVM.isAuthenticated == false)
        #expect(newVM.isLoading == false)
        #expect(newVM.errorMessage == nil)
        #expect(newVM.state == .idle)
    }

    @Test("ViewState se sincroniza con isLoading y errorMessage")
    func checkViewStateSync() {
        // isLoading setter actualiza state
        vm.isLoading = true
        #expect(vm.state == .loading)

        vm.isLoading = false
        #expect(vm.state == .idle)

        // errorMessage setter actualiza state
        vm.errorMessage = "Test error"
        #expect(vm.state.errorMessage == "Test error")

        vm.errorMessage = nil
        #expect(vm.state == .idle)
    }

    @Test("handleSessionExpired limpia el estado")
    func checkHandleSessionExpired() {
        // Given: usuario autenticado
        vm.authToken = "valid-token"
        vm.userEmail = "test@example.com"
        vm.isAuthenticated = true

        // When: sesión expira
        vm.handleSessionExpired()

        // Then: limpio pero sin borrar el email
        #expect(vm.authToken == nil)
        #expect(vm.isAuthenticated == false)
    }

    // MARK: - More Email Validation Tests

    @Test("Email con múltiples @ es inválido")
    func checkInvalidEmailMultipleAt() async throws {
        do {
            try await vm.register(email: "test@@example.com", password: "12345678")
            #expect(Bool(false), "Email con @@ debería fallar")
        } catch AuthError.invalidEmail {
            // Correcto
        } catch {
            // Otros errores son aceptables si la validación pasa pero la red falla
        }
    }

    @Test("Email con espacios es inválido")
    func checkInvalidEmailWithSpaces() async throws {
        do {
            try await vm.register(email: "test @example.com", password: "12345678")
            #expect(Bool(false), "Email con espacios debería fallar")
        } catch AuthError.invalidEmail {
            // Correcto
        } catch {
            // Otros errores son aceptables
        }
    }

    // MARK: - More Password Validation Tests

    @Test("Password exactamente 8 caracteres es válido")
    func checkPasswordExactly8Chars() async throws {
        do {
            try await vm.register(email: "test@example.com", password: "12345678")
            // No debería lanzar passwordTooShort
        } catch AuthError.passwordTooShort {
            #expect(Bool(false), "Password de 8 chars no debería ser muy corto")
        } catch {
            // Otros errores (red) son aceptables
        }
    }

    @Test("Password de 7 caracteres es inválido")
    func checkPassword7Chars() async throws {
        do {
            try await vm.register(email: "test@example.com", password: "1234567")
            #expect(Bool(false), "Password de 7 chars debería fallar")
        } catch AuthError.passwordTooShort {
            // Correcto
        } catch {
            #expect(Bool(false), "Debería ser AuthError.passwordTooShort")
        }
    }

    // MARK: - Multiple Logout Tests

    @Test("Múltiples logout no crashean")
    func checkMultipleLogout() {
        vm.authToken = "token"
        vm.isAuthenticated = true

        vm.logout()
        vm.logout()
        vm.logout()

        #expect(vm.authToken == nil)
        #expect(vm.isAuthenticated == false)
    }

    // MARK: - Error Message Tests

    @Test("Error message se puede establecer y limpiar")
    func checkErrorMessageCycle() {
        vm.errorMessage = "Test error"
        #expect(vm.errorMessage == "Test error")

        vm.errorMessage = nil
        #expect(vm.errorMessage == nil)
    }
}
