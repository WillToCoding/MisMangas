//
//  ServiceProtocols.swift
//  MisMangas
//
//  Created by Claude on 23/02/26.
//

import Foundation

// MARK: - Keychain Service Protocol

/// Protocolo para abstracción del Keychain.
/// Permite inyección de dependencias y testing.
///
/// **Implementaciones:**
/// - `KeychainHelper` - Producción (Keychain real)
/// - `KeychainTest` - Testing (en memoria)
protocol KeychainServiceProtocol {
    // Token
    func saveToken(_ token: String)
    func getToken() -> String?
    func deleteToken()

    // Email
    func saveEmail(_ email: String)
    func getEmail() -> String?
    func deleteEmail()

    // DeepL API Key
    func saveDeepLApiKey(_ apiKey: String)
    func getDeepLApiKey() -> String?
    func deleteDeepLApiKey()

    // Token Date
    func saveTokenDate(_ date: Date)
    func getTokenDate() -> Date?
    func deleteTokenDate()
    func shouldRenewToken() -> Bool

    // Clear all
    func clearAll()
}

// MARK: - Conformances

extension KeychainHelper: KeychainServiceProtocol {}
