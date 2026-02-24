//
//  TranslationService.swift
//  MisMangas
//
//  Created by Juan Carlos on 24/12/25.
//

import Foundation
import SwiftData

// MARK: - DeepL Translation Service
@MainActor
@Observable
final class TranslationService {
    private let baseURL = "https://api-free.deepl.com/v2/translate"
    private let keychain: KeychainServiceProtocol

    /// Crea una nueva instancia del servicio de traducción.
    ///
    /// - Parameter keychain: Servicio de Keychain. Por defecto usa `KeychainHelper`.
    init(keychain: KeychainServiceProtocol = KeychainHelper()) {
        self.keychain = keychain
    }

    // API Key almacenada en Keychain (encriptada y sincronizada via iCloud Keychain)
    var apiKey: String {
        get { keychain.getDeepLApiKey() ?? "" }
        set {
            if newValue.isEmpty {
                keychain.deleteDeepLApiKey()
            } else {
                keychain.saveDeepLApiKey(newValue)
            }
        }
    }

    var isConfigured: Bool {
        !apiKey.isEmpty
    }

    // Caché en memoria para la sesión actual
    private var memoryCache: [String: String] = [:]

    // MARK: - Translation

    /// Traduce texto usando DeepL API
    /// - Parameters:
    ///   - text: Texto a traducir (en inglés)
    ///   - targetLanguage: Código de idioma destino (ES, JA, AR, etc.)
    /// - Returns: Texto traducido
    func translate(_ text: String, to targetLanguage: String) async throws -> String {
        // Si el texto está vacío, devolver vacío
        guard !text.isEmpty else { return "" }

        // Si no hay API key configurada, devolver original
        guard isConfigured else { return text }

        // Crear clave de caché
        let cacheKey = "\(text.hashValue)_\(targetLanguage)"

        // Buscar en caché de memoria
        if let cached = memoryCache[cacheKey] {
            return cached
        }

        // Preparar request
        guard let url = URL(string: baseURL) else {
            throw TranslationError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")

        // Mapear código de idioma al formato DeepL
        let deeplLanguage = mapToDeepLLanguage(targetLanguage)

        // Body de la petición
        let bodyParams = [
            "text": text,
            "target_lang": deeplLanguage
        ]
        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        // Realizar petición
        let (data, response) = try await URLSession.shared.data(for: request)

        // Verificar respuesta
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let result = try JSONDecoder().decode(DeepLResponse.self, from: data)
            let translatedText = result.translations.first?.text ?? text

            // Guardar en caché
            memoryCache[cacheKey] = translatedText

            return translatedText

        case 403:
            throw TranslationError.invalidAPIKey
        case 456:
            throw TranslationError.quotaExceeded
        default:
            throw TranslationError.apiError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Helper Methods

    /// Mapea código de idioma iOS al formato DeepL
    private func mapToDeepLLanguage(_ languageCode: String) -> String {
        switch languageCode.lowercased() {
        case "es": return "ES"
        case "en": return "EN"
        case "ja": return "JA"
        case "ar": return "AR"
        case "de": return "DE"
        case "fr": return "FR"
        case "it": return "IT"
        case "pt": return "PT"
        case "zh": return "ZH"
        case "ko": return "KO"
        default: return languageCode.uppercased()
        }
    }

    /// Obtiene el código de idioma actual del dispositivo
    var currentLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    /// Indica si el idioma actual necesita traducción (no es inglés)
    var needsTranslation: Bool {
        currentLanguageCode != "en"
    }

    /// Limpia la caché en memoria
    func clearCache() {
        memoryCache.removeAll()
    }
}

// MARK: - DeepL Response Models

struct DeepLResponse: Codable {
    let translations: [DeepLTranslation]
}

struct DeepLTranslation: Codable {
    let detectedSourceLanguage: String?
    let text: String

    enum CodingKeys: String, CodingKey {
        case detectedSourceLanguage = "detected_source_language"
        case text
    }
}

// MARK: - Translation Errors

enum TranslationError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidAPIKey
    case quotaExceeded
    case apiError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "translation_error_url")
        case .invalidResponse:
            return String(localized: "translation_error_response")
        case .invalidAPIKey:
            return String(localized: "translation_error_api_key")
        case .quotaExceeded:
            return String(localized: "translation_error_quota")
        case .apiError(let code):
            return String(localized: "translation_error_generic \(code)")
        }
    }
}
