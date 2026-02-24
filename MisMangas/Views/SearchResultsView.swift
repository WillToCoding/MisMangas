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
    @State private var searchText = ""
    @State private var viewModel = MangaViewModel()
    @State private var filterOptionsVM = FilterViewModel()
    @State private var searchTask: Task<Void, Never>?
    @State private var showFilters = false
    @Namespace private var namespace

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
                filterSheet
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

    // MARK: - Filter Sheet

    private var filterSheet: some View {
        NavigationStack {
            List {
                // MARK: - Demographics
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(DemographicsConfig.list, id: \.key) { config in
                                Button {
                                    if viewModel.filters.demographics.contains(config.key) {
                                        viewModel.filters.demographics.remove(config.key)
                                    } else {
                                        viewModel.filters.demographics.removeAll()
                                        viewModel.filters.demographics.insert(config.key)
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: config.icon)
                                            .foregroundStyle(config.color)
                                        Text(config.title)
                                            .lineLimit(1)
                                            .fixedSize()
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        viewModel.filters.demographics.contains(config.key)
                                            ? config.color.opacity(0.2)
                                            : Color.gray.opacity(0.1),
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                viewModel.filters.demographics.contains(config.key)
                                                    ? config.color
                                                    : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("filter_demographics")
                }

                // MARK: - Sort
                Section {
                    Picker("sort_by", selection: $viewModel.filters.sortBy) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.localizedName).tag(option)
                        }
                    }
                }

                // MARK: - Genres
                if !filterOptionsVM.availableGenres.isEmpty {
                    Section {
                        FlowLayout(spacing: 8) {
                            ForEach(filterOptionsVM.availableGenres, id: \.self) { genre in
                                FilterChipView(
                                    title: localizedAPIValue(genre),
                                    isSelected: viewModel.filters.genres.contains(genre),
                                    color: .blue
                                ) {
                                    if viewModel.filters.genres.contains(genre) {
                                        viewModel.filters.genres.remove(genre)
                                    } else {
                                        viewModel.filters.genres.insert(genre)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        HStack {
                            Text("filter_genres")
                            if !viewModel.filters.genres.isEmpty {
                                Text("\(viewModel.filters.genres.count)")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.blue, in: Capsule())
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }

                // MARK: - Themes
                if !filterOptionsVM.availableThemes.isEmpty {
                    Section {
                        FlowLayout(spacing: 8) {
                            ForEach(filterOptionsVM.availableThemes, id: \.self) { theme in
                                FilterChipView(
                                    title: localizedAPIValue(theme),
                                    isSelected: viewModel.filters.themes.contains(theme),
                                    color: .purple
                                ) {
                                    if viewModel.filters.themes.contains(theme) {
                                        viewModel.filters.themes.remove(theme)
                                    } else {
                                        viewModel.filters.themes.insert(theme)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        HStack {
                            Text("filter_themes")
                            if !viewModel.filters.themes.isEmpty {
                                Text("\(viewModel.filters.themes.count)")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.purple, in: Capsule())
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
            }
            .navigationTitle("filter_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action_cancel") {
                        showFilters = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showFilters = false
                        performFilteredSearch()
                    } label: {
                        Text("action_apply_filters")
                            .bold()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Perform Filtered Search

    private func performFilteredSearch() {
        viewModel.filters.searchText = searchText.trimmingCharacters(in: .whitespaces)
        Task {
            await viewModel.applyFilters(page: 1, per: 50)
        }
    }

    // MARK: - Results List (por demografía)

    private var resultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                // Stats
                HStack {
                    Text("search_results_count \(viewModel.mangas.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)

                // Secciones por demografía
                ForEach(DemographicsConfig.list, id: \.key) { config in
                    let mangas = mangasByDemographic(config.key)
                    if !mangas.isEmpty {
                        section(title: config.title, icon: config.icon, color: config.color, mangas: mangas)
                    }
                }

                // Sin demografía
                let other = mangasWithoutDemographic()
                if !other.isEmpty {
                    section(title: "section_other", icon: "square.grid.2x2", color: .gray, mangas: other)
                }

                // Cargar más
                if let metadata = viewModel.metadata,
                   metadata.page < metadata.total / metadata.per {
                    loadMoreButton
                }

                Spacer(minLength: 50)
            }
            .padding(.top)
        }
    }

    // MARK: - Section

    private func section(title: LocalizedStringKey, icon: String, color: Color, mangas: [Manga]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.title3.bold())
                    .foregroundStyle(color)

                Text("(\(mangas.count))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(mangas) { manga in
                        NavigationLink(value: manga) {
                            MangaCard(manga: manga, namespace: namespace)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Grouping

    private func mangasByDemographic(_ demographic: String) -> [Manga] {
        viewModel.mangas.filter { $0.demographics.contains { $0.demographic == demographic } }
    }

    private func mangasWithoutDemographic() -> [Manga] {
        viewModel.mangas.filter { $0.demographics.isEmpty }
    }

    // MARK: - Load More

    private var loadMoreButton: some View {
        HStack {
            Spacer()
            Button {
                Task {
                    let nextPage = (viewModel.metadata?.page ?? 0) + 1
                    if viewModel.filters.isActive {
                        await viewModel.applyFilters(page: nextPage, per: 50)
                    } else {
                        await viewModel.searchMangas(text: searchText, contains: true, page: nextPage, per: 50)
                    }
                }
            } label: {
                if viewModel.state.isLoading {
                    ProgressView()
                } else {
                    Label("action_load_more", systemImage: "arrow.down.circle")
                }
            }
            .disabled(viewModel.state.isLoading)
            Spacer()
        }
        .padding()
    }

    // MARK: - Empty Search

    private var emptySearchView: some View {
        ContentUnavailableView {
            Label("search_prompt_title", systemImage: "magnifyingglass")
        } description: {
            Text("search_prompt_description")
        }
    }

    // MARK: - No Results

    private var noResultsView: some View {
        ContentUnavailableView.search(text: searchText)
    }
}

// MARK: - Filter Chip View

private struct FilterChipView: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .foregroundStyle(isSelected ? color : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview(traits: .sampleData) {
    SearchResultsView()
}
