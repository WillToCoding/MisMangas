//
//  KeychainHelper.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import Foundation
import Security

/// Helper para gestionar datos sensibles en el Keychain de iOS
final class KeychainHelper {
    // Keys para identificar los items en Keychain
    private let tokenKey = "com.mismangas.authToken"
    private let emailKey = "com.mismangas.userEmail"

    // Keychain Access Group para compartir entre iOS y watchOS
    // Formato: $(AppIdentifierPrefix)BUNDLE_ID
    // En runtime, $(AppIdentifierPrefix) se expande al Team ID
    private let accessGroup: String = {
        let bundleID = "com.murtidev.MisMangas"

        // Intentar obtener el App Identifier Prefix desde los entitlements
        if let accessGroups = Bundle.main.object(forInfoDictionaryKey: "AppIdentifierPrefix") as? String {
            return accessGroups + bundleID
        }

        // Fallback: usar el Team ID hardcodeado
        return "RUFCGDXK94.com.murtidev.MisMangas"
    }()

    // MARK: - Token Management

    /// Guarda el token de autenticación en Keychain
    func saveToken(_ token: String) {
        print("[KEYCHAIN] Guardando token, accessGroup: \(accessGroup)")
        save(key: tokenKey, value: token)
    }

    /// Obtiene el token guardado en Keychain
    func getToken() -> String? {
        print("[KEYCHAIN] Intentando obtener token, accessGroup: \(accessGroup)")
        let token = get(key: tokenKey)
        print("[KEYCHAIN] Resultado: \(token != nil ? "Token encontrado" : "Token NO encontrado")")
        return token
    }

    /// Elimina el token del Keychain
    func deleteToken() {
        delete(key: tokenKey)
    }

    // MARK: - Email Management

    /// Guarda el email del usuario (para auto-login)
    func saveEmail(_ email: String) {
        save(key: emailKey, value: email)
    }

    /// Obtiene el email guardado
    func getEmail() -> String? {
        return get(key: emailKey)
    }

    /// Elimina el email del Keychain
    func deleteEmail() {
        delete(key: emailKey)
    }

    // MARK: - Private Methods

    /// Guarda un valor en Keychain con iCloud Keychain sync
    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrAccessGroup as String: accessGroup,      // Compartir entre targets (iOS/watchOS)
            kSecAttrSynchronizable as String: true           // iCloud Keychain sync entre dispositivos
        ]

        print("[KEYCHAIN SAVE] key: \(key), accessGroup: \(accessGroup), synchronizable: true")

        // Eliminar cualquier valor existente
        SecItemDelete(query as CFDictionary)

        // Añadir el nuevo valor
        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            print("[KEYCHAIN SAVE] SUCCESS - Token will sync via iCloud Keychain")
        } else {
            print("[KEYCHAIN SAVE] ERROR for key: \(key), status: \(status)")
        }
    }

    /// Obtiene un valor del Keychain (incluyendo items sincronizados por iCloud)
    private func get(key: String) -> String? {
        // Buscar items tanto sincronizables como no-sincronizables
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessGroup as String: accessGroup,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny  // Buscar ambos tipos
        ]

        print("[KEYCHAIN GET] Buscando key: \(key) (including iCloud synced items)")

        var result: AnyObject?
        var status = SecItemCopyMatching(query as CFDictionary, &result)

        // Si NO se encuentra con accessGroup, intentar SIN accessGroup (migración de tokens viejos)
        if status != errSecSuccess {
            print("[KEYCHAIN GET] No encontrado con accessGroup, intentando sin accessGroup (migración)")
            query.removeValue(forKey: kSecAttrAccessGroup as String)
            result = nil
            status = SecItemCopyMatching(query as CFDictionary, &result)

            // Si lo encuentra sin accessGroup, MIGRARLO al nuevo formato
            if status == errSecSuccess,
               let data = result as? Data,
               let value = String(data: data, encoding: .utf8) {
                print("[KEYCHAIN MIGRATION] Token antiguo encontrado, migrando a iCloud Keychain")
                // Eliminar el viejo
                let deleteQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrAccount as String: key
                ]
                SecItemDelete(deleteQuery as CFDictionary)
                // Guardar con accessGroup + synchronizable
                save(key: key, value: value)
                print("[KEYCHAIN MIGRATION] Migracion completada")
                return value
            }
        }

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            print("[KEYCHAIN GET] NOT FOUND for key: \(key), status: \(status)")
            return nil
        }

        print("[KEYCHAIN GET] SUCCESS for key: \(key)")
        return value
    }

    /// Elimina un valor del Keychain (incluyendo items sincronizados)
    private func delete(key: String) {
        // Eliminar items sincronizables y no-sincronizables
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: accessGroup,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny  // Eliminar ambos tipos
        ]

        var status = SecItemDelete(query as CFDictionary)

        // También intentar eliminar sin accessGroup (por si hay items viejos)
        if status == errSecItemNotFound {
            query.removeValue(forKey: kSecAttrAccessGroup as String)
            status = SecItemDelete(query as CFDictionary)
        }

        if status == errSecSuccess {
            print("[KEYCHAIN DELETE] SUCCESS: \(key)")
        } else if status != errSecItemNotFound {
            print("[KEYCHAIN DELETE] ERROR eliminando: \(key), status: \(status)")
        }
    }

    // MARK: - Token Date Management (UserDefaults)

    private let tokenDateKey = "com.mismangas.tokenDate"

    /// Guarda la fecha de creación del token
    func saveTokenDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: tokenDateKey)
    }

    /// Obtiene la fecha de creación del token
    func getTokenDate() -> Date? {
        UserDefaults.standard.object(forKey: tokenDateKey) as? Date
    }

    /// Elimina la fecha del token
    func deleteTokenDate() {
        UserDefaults.standard.removeObject(forKey: tokenDateKey)
    }

    /// Verifica si el token necesita renovarse (más de 2 días)
    func shouldRenewToken() -> Bool {
        guard let tokenDate = getTokenDate() else {
            return false // No hay token
        }

        let daysSinceCreation = Calendar.current.dateComponents([.day], from: tokenDate, to: Date()).day ?? 0
        return daysSinceCreation >= 2
    }

    /// Limpia TODOS los datos del Keychain de la app
    func clearAll() {
        deleteToken()
        deleteEmail()
        deleteTokenDate()
    }
}
