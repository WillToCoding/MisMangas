//
//  FilterViewModel.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import Foundation

@MainActor
@Observable
final class FilterViewModel {
    var availableGenres: [String] = []
    var availableDemographics: [String] = []
    var availableThemes: [String] = []

    var isLoading = false
    var errorMessage: String?

    private let repository = NetworkRepository()

    /// Carga todas las opciones de filtros desde la API en paralelo
    func loadFilterOptions() async {
        isLoading = true
        errorMessage = nil

        // Ejecutar las 3 peticiones en paralelo con async let
        async let genres = repository.getGenres()
        async let demographics = repository.getDemographics()
        async let themes = repository.getThemes()

        do {
            // Esperar a que todas terminen
            availableGenres = try await genres
            availableDemographics = try await demographics
            availableThemes = try await themes
        } catch {
            errorMessage = "Error al cargar opciones de filtros: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
