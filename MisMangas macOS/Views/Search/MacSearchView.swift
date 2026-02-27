//
//  MacSearchView.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 22/2/26.
//

import SwiftUI

struct MacSearchView: View {
    @Binding var selection: Manga?

    @State private var filterVM = MangaViewModel()
    @State private var filterOptionsVM = FilterViewModel()
    @State private var searchText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                searchHeader
                    .padding(.horizontal, 20)

                demographicsSection
                    .padding(.horizontal, 20)

                Divider()
                    .padding(.horizontal, 20)

                advancedFiltersSection
                    .padding(.horizontal, 20)

                resultsContent

                Spacer(minLength: 50)
            }
            .padding(.vertical, 20)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("nav_search")
        .toolbar { toolbarContent }
        .task {
            await filterOptionsVM.loadFilterOptions()
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem {
            Button {
                searchText = ""
                filterVM.filters.clear()
                filterVM.mangas = []
            } label: {
                Image(systemName: "xmark.circle")
            }
            .help("action_clear_filters")
            .disabled(searchText.isEmpty && !filterVM.filters.isActive && filterVM.mangas.isEmpty)
        }
    }

    // MARK: - Search Header

    private var searchHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("filter_search")
                .font(.headline)

            HStack(spacing: 12) {
                TextField("search_placeholder", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { performSearch() }

                Button {
                    performSearch()
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .buttonStyle(.borderedProminent)
                .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty && !filterVM.filters.isActive)
            }
        }
    }

    // MARK: - Demographics Section

    private var demographicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("filter_demographics")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DemographicsConfig.list) { config in
                        demographicButton(config: config)
                    }
                }
            }
        }
    }

    private func demographicButton(config: DemographicSection) -> some View {
        let isSelected = filterVM.filters.demographics.contains(config.id)
        return Button {
            filterVM.filters.demographics.removeAll()
            filterVM.filters.demographics.insert(config.id)
            performSearch()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: config.icon)
                    .foregroundStyle(config.color)
                Text(config.title)
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? config.color.opacity(0.2) : Color.gray.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 8)
            )
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? config.color : Color.clear, lineWidth: 2)
        )
    }

    // MARK: - Advanced Filters Section

    private var advancedFiltersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sortPicker
            genresFilter
            themesFilter
            applyButton
        }
    }

    private var sortPicker: some View {
        HStack {
            Text("sort_by")
                .font(.headline)
            Spacer()
            Picker("sort_by", selection: $filterVM.filters.sortBy) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.localizedName).tag(option)
                }
            }
            .labelsHidden()
            .frame(width: 150)
        }
    }

    private var genresFilter: some View {
        Group {
            if !filterOptionsVM.availableGenres.isEmpty {
                DisclosureGroup {
                    MacFlowLayout(spacing: 6) {
                        ForEach(filterOptionsVM.availableGenres, id: \.self) { genre in
                            MacFilterChip(
                                title: localizedAPIValue(genre),
                                isSelected: filterVM.filters.genres.contains(genre),
                                color: .blue
                            ) {
                                if filterVM.filters.genres.contains(genre) {
                                    filterVM.filters.genres.remove(genre)
                                } else {
                                    filterVM.filters.genres.insert(genre)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                } label: {
                    filterLabel(title: "filter_genres", count: filterVM.filters.genres.count, color: .blue)
                }
            }
        }
    }

    private var themesFilter: some View {
        Group {
            if !filterOptionsVM.availableThemes.isEmpty {
                DisclosureGroup {
                    MacFlowLayout(spacing: 6) {
                        ForEach(filterOptionsVM.availableThemes, id: \.self) { theme in
                            MacFilterChip(
                                title: localizedAPIValue(theme),
                                isSelected: filterVM.filters.themes.contains(theme),
                                color: .purple
                            ) {
                                if filterVM.filters.themes.contains(theme) {
                                    filterVM.filters.themes.remove(theme)
                                } else {
                                    filterVM.filters.themes.insert(theme)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                } label: {
                    filterLabel(title: "filter_themes", count: filterVM.filters.themes.count, color: .purple)
                }
            }
        }
    }

    private func filterLabel(title: LocalizedStringKey, count: Int, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            if count > 0 {
                Text("\(count)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
    }

    private var applyButton: some View {
        Button {
            performSearch()
        } label: {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("action_apply_filters")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty && !filterVM.filters.isActive)
    }

    // MARK: - Results Content

    private var resultsContent: some View {
        Group {
            if filterVM.state.isLoading {
                HStack {
                    Spacer()
                    ProgressView("loading_mangas")
                    Spacer()
                }
                .padding(.top, 40)
            } else if !filterVM.mangas.isEmpty {
                Divider()
                    .padding(.horizontal, 20)
                resultsSection
            } else if filterVM.filters.isActive {
                ContentUnavailableView("filter_no_results", systemImage: "magnifyingglass")
                    .padding(.top, 40)
            }
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label("section_filtered_results", systemImage: "line.3.horizontal.decrease")
                    .font(.title3.bold())
                Text("(\(filterVM.mangas.count))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)

            ForEach(DemographicsConfig.list) { config in
                let mangas = filterVM.mangas.filter { manga in
                    manga.demographics.contains { $0.demographic == config.id }
                }
                if !mangas.isEmpty {
                    resultSection(title: config.title, icon: config.icon, color: config.color, mangas: mangas)
                }
            }

            let otherMangas = filterVM.mangas.filter { $0.demographics.isEmpty }
            if !otherMangas.isEmpty {
                resultSection(title: "section_other", icon: "square.grid.2x2", color: .gray, mangas: otherMangas)
            }
        }
    }

    private func resultSection(title: LocalizedStringKey, icon: String, color: Color, mangas: [Manga]) -> some View {
        MacHorizontalSection(title: title, icon: icon, color: color, itemCount: mangas.count) {
            ForEach(Array(mangas.enumerated()), id: \.element.id) { index, manga in
                MacMangaCard(manga: manga)
                    .id(index)
                    .onTapGesture { selection = manga }
            }
        }
    }

    // MARK: - Actions

    private func performSearch() {
        filterVM.filters.searchText = searchText.trimmingCharacters(in: .whitespaces)
        Task {
            await filterVM.applyFilters(page: 1, per: 20)
        }
    }
}

#Preview {
    @Previewable @State var selection: Manga? = nil
    MacSearchView(selection: $selection)
        .frame(width: 600, height: 800)
}
