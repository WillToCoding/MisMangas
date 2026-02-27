//
//  VisionSearchView.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 18/02/26.
//

import SwiftUI

struct VisionSearchView: View {
    @Environment(MangaViewModel.self) var viewModel
    @State var searchText = ""
    @State var filters = MangaFilters()
    @State var hasSearched = false
    @State var showFilters = false
    @State private var filterVM = FilterViewModel()

    var mangasByDemographic: [String: [Manga]] {
        var grouped: [String: [Manga]] = [:]
        for manga in viewModel.mangas {
            if let demographic = manga.demographics.first?.demographic {
                grouped[demographic, default: []].append(manga)
            } else {
                grouped["Other", default: []].append(manga)
            }
        }
        return grouped
    }

    var activeFiltersCount: Int {
        var count = 0
        if !filters.genres.isEmpty { count += filters.genres.count }
        if !filters.demographics.isEmpty { count += filters.demographics.count }
        if filters.minScore != nil { count += 1 }
        if filters.status != nil { count += 1 }
        return count
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 40) {
                searchControls

                if activeFiltersCount > 0 {
                    activeFiltersPills
                }

                searchResults

                Spacer(minLength: 60)
            }
            .padding(.vertical, 40)
        }
        .navigationTitle("nav_search")
        .navigationDestination(for: Manga.self) { manga in
            VisionExploreDetailView(manga: manga)
        }
        .sheet(isPresented: $showFilters) {
            VisionFilterSheet(
                filters: $filters,
                filterVM: filterVM,
                onApply: {
                    showFilters = false
                    performSearch()
                }
            )
        }
        .task {
            if filterVM.availableGenres.isEmpty {
                await filterVM.loadFilterOptions()
            }
        }
    }

    // MARK: - Actions

    func performSearch() {
        hasSearched = true
        viewModel.filters = filters
        viewModel.filters.searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            if filters.isActive || !searchText.isEmpty {
                await viewModel.applyFilters(page: 1, per: 24)
            } else {
                viewModel.mangas = []
            }
        }
    }
}

#Preview {
    NavigationStack {
        VisionSearchView()
            .environment(MangaViewModel())
    }
}
