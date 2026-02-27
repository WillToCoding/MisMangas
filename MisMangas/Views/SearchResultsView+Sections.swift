//
//  SearchResultsView+Sections.swift
//  MisMangas
//
//  Created by Juan Carlos on 2/2/26.
//

import SwiftUI

// MARK: - Sections

extension SearchResultsView {
    // MARK: - Results List (por demografía)

    var resultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                // Stats
                HStack {
                    Text("search_results_count \(viewModel.mangas.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityHeader()
                    Spacer()
                }
                .padding(.horizontal)

                // Secciones por demografía
                ForEach(DemographicsConfig.list) { config in
                    let mangas = mangasByDemographic(config.id)
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

    func section(title: LocalizedStringKey, icon: String, color: Color, mangas: [Manga]) -> some View {
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
            .accessibilityElement(children: .combine)
            .accessibilityHeader(.h2)

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

    func mangasByDemographic(_ demographic: String) -> [Manga] {
        viewModel.mangas.filter { $0.demographics.contains { $0.demographic == demographic } }
    }

    func mangasWithoutDemographic() -> [Manga] {
        viewModel.mangas.filter { $0.demographics.isEmpty }
    }

    // MARK: - Load More

    var loadMoreButton: some View {
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
                        .accessibilityLabel(String(localized: "accessibility_loading_more"))
                } else {
                    Label("action_load_more", systemImage: "arrow.down.circle")
                }
            }
            .disabled(viewModel.state.isLoading)
            .accessibilityLabel(String(localized: "action_load_more"))
            .accessibilityHint(String(localized: "accessibility_load_more_hint"))
            Spacer()
        }
        .padding()
    }

    // MARK: - Empty Search

    var emptySearchView: some View {
        ContentUnavailableView {
            Label("search_prompt_title", systemImage: "magnifyingglass")
        } description: {
            Text("search_prompt_description")
        }
    }

    // MARK: - No Results

    var noResultsView: some View {
        ContentUnavailableView.search(text: searchText)
    }
}
