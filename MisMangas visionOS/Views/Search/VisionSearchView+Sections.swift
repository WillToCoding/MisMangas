//
//  VisionSearchView+Sections.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 26/02/26.
//

import SwiftUI

// MARK: - Search Controls

extension VisionSearchView {
    var searchControls: some View {
        HStack(spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("search_placeholder", text: $searchText)
                    .textFieldStyle(.plain)
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
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))

            Button {
                showFilters = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    Text("nav_filter")
                    if activeFiltersCount > 0 {
                        Text("\(activeFiltersCount)")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.white, in: Capsule())
                            .foregroundStyle(.blue)
                    }
                }
            }
            .buttonStyle(.bordered)
            .tint(activeFiltersCount > 0 ? .blue : .gray)

            Button {
                performSearch()
            } label: {
                Label("action_search", systemImage: "magnifyingglass")
            }
            .buttonStyle(.borderedProminent)
            .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty && !filters.isActive)
        }
        .padding(.horizontal, 60)
    }
}

// MARK: - Active Filters Pills

extension VisionSearchView {
    var activeFiltersPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(filters.demographics), id: \.self) { demo in
                    VisionFilterPill(text: localizedAPIValue(demo), color: .purple) {
                        filters.demographics.remove(demo)
                        if hasSearched { performSearch() }
                    }
                }
                ForEach(Array(filters.genres), id: \.self) { genre in
                    VisionFilterPill(text: localizedAPIValue(genre), color: .blue) {
                        filters.genres.remove(genre)
                        if hasSearched { performSearch() }
                    }
                }
                if let score = filters.minScore {
                    VisionFilterPill(text: "≥ \(score.formatted(.number.precision(.fractionLength(1))))", color: .yellow) {
                        filters.minScore = nil
                        if hasSearched { performSearch() }
                    }
                }
                if let status = filters.status {
                    VisionFilterPill(text: status.localizedName, color: .green) {
                        filters.status = nil
                        if hasSearched { performSearch() }
                    }
                }

                Button {
                    filters.clear()
                    if hasSearched { performSearch() }
                } label: {
                    Label("action_clear_filters", systemImage: "xmark.circle.fill")
                        .font(.callout)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding(.horizontal, 60)
        }
    }
}

// MARK: - Search Results

extension VisionSearchView {
    var searchResults: some View {
        Group {
            if viewModel.state.isLoading {
                loadingView
            } else if hasSearched && viewModel.mangas.isEmpty {
                noResultsView
            } else if !viewModel.mangas.isEmpty {
                resultsGrouped
            } else {
                emptyState
            }
        }
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView("searching")
                .font(.title2)
            Spacer()
        }
        .padding(.top, 60)
    }

    private var noResultsView: some View {
        ContentUnavailableView(
            "filter_no_results",
            systemImage: "magnifyingglass",
            description: Text("search_try_another")
        )
        .padding(.top, 60)
    }

    private var resultsGrouped: some View {
        Group {
            ForEach(DemographicsConfig.list) { config in
                if let mangas = mangasByDemographic[config.id], !mangas.isEmpty {
                    VisionHorizontalSection(
                        title: config.title,
                        icon: config.icon,
                        color: config.color
                    ) {
                        ForEach(mangas) { manga in
                            NavigationLink(value: manga) {
                                VisionExploreCard(manga: manga)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if let otherMangas = mangasByDemographic["Other"], !otherMangas.isEmpty {
                VisionHorizontalSection(
                    title: "section_other",
                    icon: "square.grid.2x2",
                    color: .gray
                ) {
                    ForEach(otherMangas) { manga in
                        NavigationLink(value: manga) {
                            VisionExploreCard(manga: manga)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            Text("search_hint")
                .font(.title2)
                .foregroundStyle(.secondary)

            if activeFiltersCount == 0 {
                Text("search_or_use_filters")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}
