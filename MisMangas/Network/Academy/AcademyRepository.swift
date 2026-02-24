//
//  AcademyRepository.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import Foundation
import NetworkAPI

// MARK: - Academy Repository
/// Repositorio para interactuar con la API de Academy (mymanga-acacademy)
struct AcademyRepository: NetworkInteractor {

    // MARK: - List Endpoints

    func getMangas(page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await getJSON(.get(url: .listMangas.withPagination(page: page, per: per)), type: PaginatedResponseDTO<MangaDTO>.self)
            .toPaginatedResponse
    }

    func getBestMangas(page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await getJSON(.get(url: .bestMangas.withPagination(page: page, per: per)), type: PaginatedResponseDTO<MangaDTO>.self)
            .toPaginatedResponse
    }

    func getAuthors() async throws -> [Author] {
        try await getJSON(.get(url: .authors), type: [AuthorDTO].self)
            .map(\.toAuthor)
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

    // MARK: - Filter by Category

    func getMangasByGenre(_ genre: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await getJSON(.get(url: .mangaByGenre(genre).withPagination(page: page, per: per)), type: PaginatedResponseDTO<MangaDTO>.self)
            .toPaginatedResponse
    }

    func getMangasByDemographic(_ demographic: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await getJSON(.get(url: .mangaByDemographic(demographic).withPagination(page: page, per: per)), type: PaginatedResponseDTO<MangaDTO>.self)
            .toPaginatedResponse
    }

    func getMangasByTheme(_ theme: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await getJSON(.get(url: .mangaByTheme(theme).withPagination(page: page, per: per)), type: PaginatedResponseDTO<MangaDTO>.self)
            .toPaginatedResponse
    }

    func getMangasByAuthor(_ authorId: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await getJSON(.get(url: .mangaByAuthor(authorId).withPagination(page: page, per: per)), type: PaginatedResponseDTO<MangaDTO>.self)
            .toPaginatedResponse
    }

    // MARK: - Search

    func searchMangasBeginsWith(_ text: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await getJSON(.get(url: .mangasBeginsWith(text).withPagination(page: page, per: per)), type: PaginatedResponseDTO<MangaDTO>.self)
            .toPaginatedResponse
    }

    func searchMangasContains(_ text: String, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await getJSON(.get(url: .mangasContains(text).withPagination(page: page, per: per)), type: PaginatedResponseDTO<MangaDTO>.self)
            .toPaginatedResponse
    }

    func searchAuthor(_ name: String) async throws -> [Author] {
        try await getJSON(.get(url: .searchAuthor(name)), type: [AuthorDTO].self)
            .map(\.toAuthor)
    }

    func getManga(byId id: Int) async throws -> Manga {
        try await getJSON(.get(url: .manga(byId: id)), type: MangaDTO.self)
            .toManga
    }

    /// Búsqueda personalizada con múltiples filtros combinados (POST)
    func searchCustom(_ search: CustomSearch, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
        try await getJSON(.post(url: .searchManga.withPagination(page: page, per: per), body: search), type: PaginatedResponseDTO<MangaDTO>.self)
            .toPaginatedResponse
    }

    // MARK: - Authentication

    /// Registra un nuevo usuario
    func registerUser(_ users: Users) async throws {
        var request = URLRequest.post(url: .users, body: users)
        request.setValue(AppConfig.academyToken, forHTTPHeaderField: "App-Token")
        try await postJSON(request, status: 201)
    }

    /// Inicia sesión y obtiene un token
    func login(email: String, password: String) async throws -> String {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let credentials = "\(cleanEmail):\(cleanPassword)"
        guard let credentialData = credentials.data(using: .utf8) else {
            throw NetworkError.invalidCredentials
        }

        let base64Credentials = credentialData.base64EncodedString()

        var request = URLRequest(url: .usersLogin)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let response = try await getJSON(request, type: TokenResponse.self)
        return response.token
    }

    /// Renueva el token de autenticación
    func renewToken(_ currentToken: String) async throws -> String {
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
        return try await getJSON(request, type: [UserMangaCollectionDTO].self)
            .map(\.toUserMangaCollection)
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

        try await postJSON(request, status: 200)
    }
}

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
