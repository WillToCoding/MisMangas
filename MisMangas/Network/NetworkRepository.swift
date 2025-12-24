//
//  NetworkRepository.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import Foundation
import NetworkAPI

struct NetworkRepository: NetworkInteractor {

    func getMangas(page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await getJSON(.get(url: .listMangas.withPagination(page: page, per: per)), type: PaginatedResponse<Manga>.self)
    }

    func getBestMangas(page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await getJSON(.get(url: .bestMangas.withPagination(page: page, per: per)), type: PaginatedResponse<Manga>.self)
    }

    func getAuthors() async throws -> [Author] {
        try await getJSON(.get(url: .authors), type: [Author].self)
    }

    func getDemographics() async throws -> [String] {
        try await getJSON(.get(url: .demographics), type: [String].self)
    }

    func getGenres() async throws -> [String] {
        try await getJSON(.get(url: .genres), type: [String].self)
    }

    func getThemes() async throws -> [String] {
        try await getJSON(.get(url: .themes), type: [String].self)
    }

    func getMangasByGenre(_ genre: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await getJSON(.get(url: .mangaByGenre(genre).withPagination(page: page, per: per)), type: PaginatedResponse<Manga>.self)
    }

    func getMangasByDemographic(_ demographic: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await getJSON(.get(url: .mangaByDemographic(demographic).withPagination(page: page, per: per)), type: PaginatedResponse<Manga>.self)
    }

    func getMangasByTheme(_ theme: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await getJSON(.get(url: .mangaByTheme(theme).withPagination(page: page, per: per)), type: PaginatedResponse<Manga>.self)
    }

    func getMangasByAuthor(_ authorId: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await getJSON(.get(url: .mangaByAuthor(authorId).withPagination(page: page, per: per)), type: PaginatedResponse<Manga>.self)
    }


    func searchMangasBeginsWith(_ text: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await getJSON(.get(url: .mangasBeginsWith(text).withPagination(page: page, per: per)), type: PaginatedResponse<Manga>.self)
    }

    func searchMangasContains(_ text: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await getJSON(.get(url: .mangasContains(text).withPagination(page: page, per: per)), type: PaginatedResponse<Manga>.self)
    }

    func searchAuthor(_ name: String) async throws -> [Author] {
        try await getJSON(.get(url: .searchAuthor(name)), type: [Author].self)
    }

    func getManga(byId id: Int) async throws -> Manga {
        try await getJSON(.get(url: .manga(byId: id)), type: Manga.self)
    }

    /// Búsqueda personalizada con múltiples filtros combinados (POST)
    func searchCustom(_ search: CustomSearch, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await getJSON(.post(url: .searchManga.withPagination(page: page, per: per), body: search), type: PaginatedResponse<Manga>.self)
    }

    // MARK: - Authentication

    /// Registra un nuevo usuario
    func registerUser(_ users: Users) async throws {
        print("DEBUG - Registrando usuario: \(users.email)")
        print("DEBUG - Password length: \(users.password.count)")

        var request = URLRequest.post(url: .users, body: users)
        request.setValue("sLGH38NhEJ0_anlIWwhsz1-LarClEohiAHQqayF0FY", forHTTPHeaderField: "App-Token")

        print("DEBUG - URL: \(request.url?.absoluteString ?? "nil")")
        print("DEBUG - Method: \(request.httpMethod ?? "nil")")
        print("DEBUG - Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("DEBUG - Body: \(bodyString)")
        }

        try await postJSON(request, status: 201)
    }

    /// Inicia sesión y obtiene un token
    func login(email: String, password: String) async throws -> String {
        // Crear credenciales en formato "email:password"
        let credentials = "\(email):\(password)"
        guard let credentialData = credentials.data(using: .utf8) else {
            throw NetworkError.invalidCredentials
        }

        // Codificar en Base64 para Basic Auth
        let base64Credentials = credentialData.base64EncodedString()

        var request = URLRequest(url: .usersLogin)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Obtener token
        let response = try await getJSON(request, type: TokenResponse.self)
        return response.token
    }

    /// Renueva el token de autenticación
    func renewToken(_ currentToken: String) async throws -> String {
        // POST sin body, solo headers
        var request = URLRequest(url: .usersRenew)
        request.httpMethod = "POST"
        request.setValue("Bearer \(currentToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let response = try await getJSON(request, type: TokenResponse.self)
        return response.token
    }

    // MARK: - Cloud Collection

    /// Obtiene la colección del usuario desde la nube
    func getUserCollection(token: String) async throws -> [UserMangaCollection] {
        var request = URLRequest.get(url: .collectionManga)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await getJSON(request, type: [UserMangaCollection].self)
    }

    /// Añade un manga a la colección en la nube
    func addToCollection(_ request: UserMangaCollectionRequest, token: String) async throws {
        var urlRequest = URLRequest.post(url: .collectionManga, body: request)
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        try await postJSON(urlRequest, status: 201)
    }

    /// Elimina un manga de la colección en la nube
    func deleteFromCollection(mangaId: Int, token: String) async throws {
        var request = URLRequest(url: .collectionManga(byId: mangaId))
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // DELETE no devuelve contenido, solo ejecutamos la request
        _ = try await getJSON(request, type: EmptyResponse.self)
    }

    // MARK: - Jikan API (Characters)

    #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
    /// Obtiene los personajes de un manga desde Jikan API
    func getMangaCharacters(mangaId: Int) async throws -> [JikanCharacterData] {
        let response = try await getJSON(
            .get(url: .mangaCharacters(mangaId: mangaId)),
            type: JikanCharactersResponse.self
        )
        return response.data
    }

    /// Obtiene mangas relacionados desde Jikan API
    func getMangaRelations(mangaId: Int) async throws -> [JikanRelation] {
        let response = try await getJSON(
            .get(url: .mangaRelations(mangaId: mangaId)),
            type: JikanRelationsResponse.self
        )
        return response.data
    }

    /// Obtiene recomendaciones de manga desde Jikan API
    func getMangaRecommendations(mangaId: Int) async throws -> [JikanRecommendation] {
        let response = try await getJSON(
            .get(url: .mangaRecommendations(mangaId: mangaId)),
            type: JikanRecommendationsResponse.self
        )
        return response.data
    }

    /// Búsqueda avanzada de mangas usando Jikan API
    func searchMangasJikan(
        query: String? = nil,
        genres: [Int]? = nil,
        minScore: Double? = nil,
        maxScore: Double? = nil,
        startYear: Int? = nil,
        endYear: Int? = nil,
        status: String? = nil,
        orderBy: String? = nil,
        sort: String? = nil,
        page: Int = 1,
        limit: Int = 25
    ) async throws -> JikanMangaSearchResponse {
        let url = URL.jikanMangaSearch(
            query: query,
            genres: genres,
            minScore: minScore,
            maxScore: maxScore,
            startYear: startYear,
            endYear: endYear,
            status: status,
            orderBy: orderBy,
            sort: sort,
            page: page,
            limit: limit
        )
        return try await getJSON(.get(url: url), type: JikanMangaSearchResponse.self)
    }
    #endif
}

// MARK: - Empty Response para DELETE
struct EmptyResponse: Codable {}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Credenciales inválidas"
        }
    }
}
