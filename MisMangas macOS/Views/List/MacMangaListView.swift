//
//  MacMangaListView.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct MacMangaListView: View {
    @Binding var selection: Manga?
    @Environment(MangaViewModel.self) private var mangaVM
    @Environment(FilterViewModel.self) private var filterVM

    @State private var searchText = ""
    @State private var showFilters = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Barra de búsqueda y filtros
            HStack {
                TextField("action_search", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isSearchFocused)
                    .onSubmit {
                        Task {
                            await performSearch()
                        }
                    }

                Button {
                    showFilters.toggle()
                } label: {
                    Label("nav_filter", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
            .padding()

            Divider()

            // Lista
            if mangaVM.state.isLoading {
                ProgressView("loading_mangas")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = mangaVM.state.errorMessage {
                ContentUnavailableView(
                    "error_title",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                List(mangaVM.mangas, selection: $selection) { manga in
                    MacMangaRow(manga: manga)
                        .tag(manga)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("nav_explore")
        .sheet(isPresented: $showFilters) {
            MacFiltersSheet()
                .environment(filterVM)
        }
        .task {
            if mangaVM.mangas.isEmpty {
                await mangaVM.fetchMangas()
            }
            await filterVM.loadFilterOptions()
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearchField)) { _ in
            isSearchFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshContent)) { _ in
            Task {
                await mangaVM.fetchMangas()
            }
        }
    }

    private func performSearch() async {
        if searchText.isEmpty {
            await mangaVM.fetchMangas()
        } else {
            await mangaVM.searchMangas(text: searchText, contains: true)
        }
    }
}

// MARK: - Filters Sheet
struct MacFiltersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FilterViewModel.self) private var filterVM
    @Environment(MangaViewModel.self) private var mangaVM

    @State private var tempFilters = MangaFilters()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("nav_filter")
                    .font(.title2.bold())

                if tempFilters.hasAdvancedFilters {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                }

                Spacer()

                Button("action_clear_filters") {
                    tempFilters.clear()
                }
                .buttonStyle(.link)
                .disabled(!tempFilters.isActive)
            }
            .padding()

            Divider()

            // Content
            if filterVM.state.isLoading {
                ProgressView("loading_mangas")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Search
                        VStack(alignment: .leading, spacing: 8) {
                            Text("filter_search")
                                .font(.headline)

                            TextField("action_search", text: $tempFilters.searchText)
                                .textFieldStyle(.roundedBorder)
                        }

                        Divider()

                        // Sort
                        VStack(alignment: .leading, spacing: 8) {
                            Text("sort_by")
                                .font(.headline)

                            Picker("sort_by", selection: $tempFilters.sortBy) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Text(option.localizedName).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        Divider()

                        // MARK: - Advanced Filters (Jikan)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("filter_advanced")
                                    .font(.headline)
                                if tempFilters.hasAdvancedFilters {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(.yellow)
                                }
                            }

                            // Minimum Score
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("filter_min_score")
                                    Spacer()
                                    if let score = tempFilters.minScore {
                                        Text(score.formatted(.number.precision(.fractionLength(1))))
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("filter_any")
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Slider(
                                    value: Binding(
                                        get: { tempFilters.minScore ?? 0 },
                                        set: { tempFilters.minScore = $0 > 0 ? $0 : nil }
                                    ),
                                    in: 0...10,
                                    step: 0.5
                                )

                                HStack {
                                    Image(systemName: "star")
                                        .font(.caption)
                                    Spacer()
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                }
                                .foregroundStyle(.yellow)
                            }

                            // Year Range
                            HStack {
                                Text("filter_year_from")
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { tempFilters.startYear ?? 0 },
                                    set: { tempFilters.startYear = $0 > 0 ? $0 : nil }
                                )) {
                                    Text("filter_any").tag(0)
                                    ForEach((1950...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) { year in
                                        Text(String(year)).tag(year)
                                    }
                                }
                                .frame(width: 100)
                            }

                            HStack {
                                Text("filter_year_to")
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { tempFilters.endYear ?? 0 },
                                    set: { tempFilters.endYear = $0 > 0 ? $0 : nil }
                                )) {
                                    Text("filter_any").tag(0)
                                    ForEach((1950...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) { year in
                                        Text(String(year)).tag(year)
                                    }
                                }
                                .frame(width: 100)
                            }

                            // Status
                            HStack {
                                Text("filter_status")
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { tempFilters.status },
                                    set: { tempFilters.status = $0 }
                                )) {
                                    Text("filter_any").tag(nil as MangaStatus?)
                                    ForEach(MangaStatus.allCases, id: \.self) { status in
                                        Text(status.localizedName).tag(status as MangaStatus?)
                                    }
                                }
                                .frame(width: 150)
                            }

                            if tempFilters.hasAdvancedFilters {
                                Text("filter_advanced_note")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Divider()

                        // Genres
                        if !filterVM.availableGenres.isEmpty {
                            FilterSection(
                                title: String(localized: "filter_genres"),
                                items: filterVM.availableGenres,
                                selectedItems: $tempFilters.genres
                            )
                        }

                        Divider()

                        // Demographics
                        if !filterVM.availableDemographics.isEmpty {
                            FilterSection(
                                title: String(localized: "filter_demographics"),
                                items: filterVM.availableDemographics,
                                selectedItems: $tempFilters.demographics
                            )
                        }

                        Divider()

                        // Themes
                        if !filterVM.availableThemes.isEmpty {
                            FilterSection(
                                title: String(localized: "filter_themes"),
                                items: filterVM.availableThemes,
                                selectedItems: $tempFilters.themes
                            )
                        }
                    }
                    .padding()
                }
            }

            Divider()

            // Footer buttons
            HStack {
                Button("action_cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("action_apply_filters") {
                    applyFilters()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 550, height: 750)
        .task {
            if filterVM.availableGenres.isEmpty {
                await filterVM.loadFilterOptions()
            }
        }
    }

    private func applyFilters() {
        mangaVM.filters = tempFilters
        Task {
            if tempFilters.isActive {
                await mangaVM.applyFilters()
            } else {
                await mangaVM.fetchMangas()
            }
        }
    }
}

// MARK: - Filter Section
struct FilterSection: View {
    let title: String
    let items: [String]
    @Binding var selectedItems: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                if !selectedItems.isEmpty {
                    Text("selected_count \(selectedItems.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Toggle(localizedAPIValue(item), isOn: Binding(
                        get: { selectedItems.contains(item) },
                        set: { isOn in
                            if isOn {
                                selectedItems.insert(item)
                            } else {
                                selectedItems.remove(item)
                            }
                        }
                    ))
                    .toggleStyle(.button)
                    .buttonStyle(.bordered)
                    .tint(selectedItems.contains(item) ? .blue : .gray)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedManga: Manga? = nil
    MacMangaListView(selection: $selectedManga)
        .environment(MangaViewModel())
        .environment(FilterViewModel())
}
