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
    @State private var searchTask: Task<Void, Never>?
    @Namespace private var namespace

    private let demographicConfig: [(key: String, title: LocalizedStringKey, icon: String, color: Color)] = [
        ("Shounen", "section_shounen", "flame.fill", .orange),
        ("Seinen", "section_seinen", "person.fill", .purple),
        ("Shoujo", "section_shoujo", "heart.fill", .pink),
        ("Josei", "section_josei", "sparkles", .indigo),
        ("Kids", "section_kids", "star.fill", .yellow)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    emptySearchView
                } else if viewModel.isLoading && viewModel.mangas.isEmpty {
                    ProgressView("searching")
                        .accessibilityLabel(String(localized: "accessibility_searching"))
                } else if viewModel.mangas.isEmpty {
                    noResultsView
                } else {
                    resultsList
                }
            }
            .navigationTitle("nav_search")
            .navigationDestination(for: Manga.self) { manga in
                MangaDetailView(manga: manga, namespace: namespace)
            }
        }
        .searchable(text: $searchText, prompt: "search_placeholder")
        .onChange(of: searchText) { oldValue, newValue in
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
                ForEach(demographicConfig, id: \.key) { config in
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
                    await viewModel.searchMangas(text: searchText, contains: true, page: nextPage, per: 50)
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Label("action_load_more", systemImage: "arrow.down.circle")
                }
            }
            .disabled(viewModel.isLoading)
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

#Preview(traits: .sampleData) {
    SearchResultsView()
}
