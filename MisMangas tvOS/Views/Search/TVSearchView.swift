//
//  TVSearchView.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 22/2/26.
//

import SwiftUI

struct TVSearchView: View {
    @State private var searchText = ""
    @State private var viewModel = MangaViewModel()
    @State private var filters = MangaFilters()
    @State private var hasSearched = false
    @State private var showFilters = false

    // Agrupar resultados por demografía
    private var mangasByDemographic: [String: [Manga]] {
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

    private var activeFiltersCount: Int {
        var count = 0
        if !filters.genres.isEmpty { count += filters.genres.count }
        if !filters.demographics.isEmpty { count += filters.demographics.count }
        if filters.minScore != nil { count += 1 }
        if filters.status != nil { count += 1 }
        return count
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 50) {
                // MARK: - Search Controls
                searchControls

                // MARK: - Results
                resultsSection

                Spacer(minLength: 100)
            }
            .padding(.vertical, 50)
        }
        .navigationTitle("nav_search")
        .navigationDestination(for: Manga.self) { manga in
            TVMangaPreviewView(manga: manga)
        }
        .fullScreenCover(isPresented: $showFilters) {
            TVFilterView(filters: $filters)
        }
        .onChange(of: showFilters) { wasShowing, isShowing in
            // Auto-search when filters change and sheet closes
            if wasShowing && !isShowing && filters.isActive {
                performSearch()
            }
        }
    }

    // MARK: - Search Controls

    private var searchControls: some View {
        VStack(spacing: 30) {
            // Search bar + filters
            HStack(spacing: 20) {
                // Search field
                HStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)

                    TextField("search_placeholder", text: $searchText)
                        .font(.system(size: 36))
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .onSubmit {
                            performSearch()
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            viewModel.mangas = []
                            hasSearched = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(30)
                .background(.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 16))

                // Filter button
                Button {
                    showFilters = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 32))
                        Text("nav_filter")
                            .font(.system(size: 28, weight: .semibold))
                        if activeFiltersCount > 0 {
                            Text("\(activeFiltersCount)")
                                .font(.system(size: 22, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(.white, in: Capsule())
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .tint(activeFiltersCount > 0 ? .blue : .gray)

                // Search button
                Button {
                    performSearch()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 28))
                        Text("action_search")
                            .font(.system(size: 28, weight: .semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty && !filters.isActive)
            }
            .padding(.horizontal, 80)

            // Active filters pills
            if activeFiltersCount > 0 {
                activeFiltersPills
            }
        }
        .focusSection()
    }

    // MARK: - Active Filters Pills

    private var activeFiltersPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(filters.demographics), id: \.self) { demo in
                    TVFilterPill(text: localizedAPIValue(demo), color: .purple) {
                        filters.demographics.remove(demo)
                        if hasSearched { performSearch() }
                    }
                }
                ForEach(Array(filters.genres), id: \.self) { genre in
                    TVFilterPill(text: localizedAPIValue(genre), color: .blue) {
                        filters.genres.remove(genre)
                        if hasSearched { performSearch() }
                    }
                }
                if let score = filters.minScore {
                    TVFilterPill(text: "≥ \(score.formatted(.number.precision(.fractionLength(1))))", color: .yellow) {
                        filters.minScore = nil
                        if hasSearched { performSearch() }
                    }
                }
                if let status = filters.status {
                    TVFilterPill(text: status.englishName, color: .green) {
                        filters.status = nil
                        if hasSearched { performSearch() }
                    }
                }

                // Clear all
                Button {
                    filters.clear()
                    if hasSearched { performSearch() }
                } label: {
                    Label("action_clear_filters", systemImage: "xmark.circle.fill")
                        .font(.system(size: 22))
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding(.horizontal, 80)
        }
        .focusSection()
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        Group {
            if viewModel.state.isLoading {
                loadingView
            } else if hasSearched && viewModel.mangas.isEmpty {
                emptyResultsView
            } else if !viewModel.mangas.isEmpty {
                searchResults
            } else {
                initialStateView
            }
        }
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView("searching")
                .font(.title)
            Spacer()
        }
        .padding(.top, 100)
    }

    private var emptyResultsView: some View {
        HStack {
            Spacer()
            ContentUnavailableView(
                "filter_no_results",
                systemImage: "magnifyingglass",
                description: Text("search_try_another")
            )
            Spacer()
        }
        .padding(.top, 50)
    }

    private var searchResults: some View {
        Group {
            // Resultados agrupados por demografía
            ForEach(DemographicsConfig.list) { config in
                if let mangas = mangasByDemographic[config.id], !mangas.isEmpty {
                    TVHorizontalSection(
                        title: config.title,
                        icon: config.icon,
                        color: config.color
                    ) {
                        ForEach(mangas) { manga in
                            NavigationLink(value: manga) {
                                TVExploreCardLabel(manga: manga)
                            }
                            .buttonStyle(.card)
                        }
                    }
                }
            }

            // Mangas sin demografía definida
            if let otherMangas = mangasByDemographic["Other"], !otherMangas.isEmpty {
                TVHorizontalSection(
                    title: "section_other",
                    icon: "square.grid.2x2.fill",
                    color: .gray
                ) {
                    ForEach(otherMangas) { manga in
                        NavigationLink(value: manga) {
                            TVExploreCardLabel(manga: manga)
                        }
                        .buttonStyle(.card)
                    }
                }
            }
        }
    }

    private var initialStateView: some View {
        HStack {
            Spacer()
            VStack(spacing: 30) {
                Image(systemName: "text.magnifyingglass")
                    .font(.system(size: 100))
                    .foregroundStyle(.secondary)

                Text("search_hint")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)

                if activeFiltersCount == 0 {
                    Text("search_or_use_filters")
                        .font(.system(size: 26))
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
        }
        .padding(.top, 100)
    }

    // MARK: - Actions

    private func performSearch() {
        hasSearched = true

        // Apply filters to viewModel
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
    let authVM = AuthViewModel()
    return NavigationStack {
        TVSearchView()
    }
    .environment(authVM)
    .environment(CloudCollectionViewModel(authVM: authVM))
}
