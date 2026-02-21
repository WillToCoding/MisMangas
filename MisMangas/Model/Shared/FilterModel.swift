//
//  FilterModel.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import Foundation
import SwiftUI

// MARK: - API Value Localization

/// Traduce valores de la API (géneros, demografías, temas) al idioma local
func localizedAPIValue(_ value: String) -> String {
    let key = "genre_" + value.lowercased()
        .replacingOccurrences(of: " ", with: "_")
        .replacingOccurrences(of: "-", with: "_")
        .replacingOccurrences(of: "(", with: "")
        .replacingOccurrences(of: ")", with: "")

    let localized = String(localized: String.LocalizationValue(key))
    // Si no existe la traducción, devuelve el valor original
    return localized == key ? value : localized
}

// MARK: - Sort Options
enum SortOption: String, CaseIterable {
    case score
    case title
    case recent

    var localizedName: String {
        switch self {
        case .score: return String(localized: "sort_score")
        case .title: return String(localized: "sort_title")
        case .recent: return String(localized: "sort_recent")
        }
    }
}

// MARK: - Manga Filters
struct MangaFilters: Equatable {
    var genres: Set<String> = []
    var demographics: Set<String> = []
    var themes: Set<String> = []
    var searchText: String = ""
    var sortBy: SortOption = .score

    // Filtros avanzados (Jikan API)
    var minScore: Double? = nil
    var startYear: Int? = nil
    var endYear: Int? = nil
    var status: MangaStatus? = nil

    /// Indica si hay algún filtro activo
    var isActive: Bool {
        !genres.isEmpty || !demographics.isEmpty || !themes.isEmpty || !searchText.isEmpty || hasAdvancedFilters
    }

    /// Indica si hay filtros avanzados que requieren Jikan API
    var hasAdvancedFilters: Bool {
        minScore != nil || startYear != nil || endYear != nil || status != nil
    }

    /// Limpia todos los filtros
    mutating func clear() {
        genres.removeAll()
        demographics.removeAll()
        themes.removeAll()
        searchText = ""
        sortBy = .score
        minScore = nil
        startYear = nil
        endYear = nil
        status = nil
    }

    /// Retorna una copia limpia de los filtros
    func cleared() -> MangaFilters {
        MangaFilters()
    }
}

// MARK: - Manga Status (Publication)
enum MangaStatus: String, CaseIterable {
    case publishing
    case complete
    case hiatus
    case discontinued
    case upcoming

    var localizedName: String {
        switch self {
        case .publishing: return String(localized: "status_publishing")
        case .complete: return String(localized: "status_finished")
        case .hiatus: return String(localized: "status_hiatus")
        case .discontinued: return String(localized: "status_discontinued")
        case .upcoming: return String(localized: "status_upcoming")
        }
    }

    var jikanValue: String {
        rawValue
    }
}

// MARK: - Reading Status (User)
/// Estado de lectura personal del usuario
enum ReadingStatus: String, CaseIterable, Codable {
    case reading
    case completed
    case planToRead
    case onHold
    case dropped

    var localizedName: String {
        switch self {
        case .reading: return String(localized: "reading_status_reading")
        case .completed: return String(localized: "reading_status_completed")
        case .planToRead: return String(localized: "reading_status_plan_to_read")
        case .onHold: return String(localized: "reading_status_on_hold")
        case .dropped: return String(localized: "reading_status_dropped")
        }
    }

    var icon: String {
        switch self {
        case .reading: return "book.fill"
        case .completed: return "checkmark.circle.fill"
        case .planToRead: return "bookmark.fill"
        case .onHold: return "pause.circle.fill"
        case .dropped: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .reading: return .blue
        case .completed: return .green
        case .planToRead: return .orange
        case .onHold: return .yellow
        case .dropped: return .red
        }
    }
}
