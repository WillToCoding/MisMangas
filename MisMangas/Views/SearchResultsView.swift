//
//  SearchResultsView.swift
//  MisMangas
//
//  Created by Juan Carlos on 2/2/26.
//

import SwiftUI
import SwiftData

/// Vista de resultados de busqueda global.
struct SearchResultsView: View {
    @State var searchText = ""
    @State var viewModel = MangaViewModel()
    @State private var filterOptionsVM = FilterViewModel()
    @State private var searchTask: Task<Void, Never>?
    @State private var showFilters = false
    @Namespace var namespace

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty && !viewModel.filters.isActive {
                    emptySearchView
                } else if viewModel.state.isLoading && viewModel.mangas.isEmpty {
                    ProgressView("searching")
                        .accessibilityLabel(String(localized: "accessibility_searching"))
                } else if viewModel.mangas.isEmpty && (viewModel.filters.isActive || !searchText.isEmpty) {
                    noResultsView
                } else {
                    resultsList
                }
            }
            .navigationTitle("nav_search")
            .navigationDestination(for: Manga.self) { manga in
                MangaDetailView(manga: manga, namespace: namespace)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showFilters.toggle()
                    } label: {
                        Image(systemName: viewModel.filters.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel(String(localized: "accessibility_show_filters"))
                }

                if viewModel.filters.isActive || !searchText.isEmpty {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            searchText = ""
                            viewModel.filters.clear()
                            viewModel.mangas = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel(String(localized: "action_clear_filters"))
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                SearchFilterSheet(
                    filters: $viewModel.filters,
                    isPresented: $showFilters,
                    filterOptionsVM: filterOptionsVM,
                    onApply: performFilteredSearch
                )
            }
        }
        .searchable(text: $searchText, prompt: "search_placeholder")
        .onSubmit(of: .search) {
            performFilteredSearch()
        }
        .onChange(of: searchText) { oldValue, newValue in
            // Solo búsqueda rápida si no hay filtros activos
            guard !viewModel.filters.isActive else { return }

            searchTask?.cancel()

            searchTask = Task {
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }

                if newValue.isEmpty {
                    viewModel.mangas = []
                } else {
                    await viewModel.searchMangas(text: newValue, contains: true, per: 50)
                }
            }
        }
        .task {
            await filterOptionsVM.loadFilterOptions()
        }
    }

    // MARK: - Perform Filtered Search

    func performFilteredSearch() {
        viewModel.filters.searchText = searchText.trimmingCharacters(in: .whitespaces)
        Task {
            await viewModel.applyFilters(page: 1, per: 50)
        }
    }
}

#Preview(traits: .sampleData) {
    SearchResultsView()
}
