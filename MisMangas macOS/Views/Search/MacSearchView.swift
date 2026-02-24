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

    private let demographicConfig: [(key: String, title: LocalizedStringKey, icon: String, color: Color)] = [
        ("Shounen", "section_shounen", "flame.fill", .orange),
        ("Seinen", "section_seinen", "person.fill", .purple),
        ("Shoujo", "section_shoujo", "heart.fill", .pink),
        ("Josei", "section_josei", "sparkles", .indigo),
        ("Kids", "section_kids", "star.fill", .yellow)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Search Header
                searchHeader
                    .padding(.horizontal, 20)

                // MARK: - Quick Demographics
                demographicsSection
                    .padding(.horizontal, 20)

                Divider()
                    .padding(.horizontal, 20)

                // MARK: - Advanced Filters
                advancedFiltersSection
                    .padding(.horizontal, 20)

                // MARK: - Results
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

                Spacer(minLength: 50)
            }
            .padding(.vertical, 20)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("nav_search")
        .toolbar {
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
        .task {
            await filterOptionsVM.loadFilterOptions()
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
                    .onSubmit {
                        performSearch()
                    }

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
                    ForEach(demographicConfig, id: \.key) { config in
                        Button {
                            filterVM.filters.demographics.removeAll()
                            filterVM.filters.demographics.insert(config.key)
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
                                filterVM.filters.demographics.contains(config.key)
                                    ? config.color.opacity(0.2)
                                    : Color.gray.opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                        }
                        .buttonStyle(.plain)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    filterVM.filters.demographics.contains(config.key)
                                        ? config.color
                                        : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    }
                }
            }
        }
    }

    // MARK: - Advanced Filters Section

    private var advancedFiltersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Sort
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

            // Genres
            if !filterOptionsVM.availableGenres.isEmpty {
                DisclosureGroup {
                    FlowLayout(spacing: 6) {
                        ForEach(filterOptionsVM.availableGenres, id: \.self) { genre in
                            FilterChip(
                                title: localizedAPIValue(genre),
                                isSelected: filterVM.filters.genres.contains(genre)
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
                    HStack {
                        Text("filter_genres")
                            .font(.headline)
                        if !filterVM.filters.genres.isEmpty {
                            Text("\(filterVM.filters.genres.count)")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                }
            }

            // Themes
            if !filterOptionsVM.availableThemes.isEmpty {
                DisclosureGroup {
                    FlowLayout(spacing: 6) {
                        ForEach(filterOptionsVM.availableThemes, id: \.self) { theme in
                            FilterChip(
                                title: localizedAPIValue(theme),
                                isSelected: filterVM.filters.themes.contains(theme)
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
                    HStack {
                        Text("filter_themes")
                            .font(.headline)
                        if !filterVM.filters.themes.isEmpty {
                            Text("\(filterVM.filters.themes.count)")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.purple, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                }
            }

            // Apply button
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
    }

    // MARK: - Results Section

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

            // Agrupar por demografía
            ForEach(demographicConfig, id: \.key) { config in
                let mangas = filterVM.mangas.filter { manga in
                    manga.demographics.contains { $0.demographic == config.key }
                }
                if !mangas.isEmpty {
                    MacHorizontalSection(
                        title: config.title,
                        icon: config.icon,
                        color: config.color,
                        itemCount: mangas.count
                    ) {
                        ForEach(Array(mangas.enumerated()), id: \.element.id) { index, manga in
                            MacMangaCard(manga: manga)
                                .id(index)
                                .onTapGesture {
                                    selection = manga
                                }
                        }
                    }
                }
            }

            // Mangas sin demografía
            let otherMangas = filterVM.mangas.filter { $0.demographics.isEmpty }
            if !otherMangas.isEmpty {
                MacHorizontalSection(
                    title: "section_other",
                    icon: "square.grid.2x2",
                    color: .gray,
                    itemCount: otherMangas.count
                ) {
                    ForEach(Array(otherMangas.enumerated()), id: \.element.id) { index, manga in
                        MacMangaCard(manga: manga)
                            .id(index)
                            .onTapGesture {
                                selection = manga
                            }
                    }
                }
            }
        }
    }

    private func performSearch() {
        filterVM.filters.searchText = searchText.trimmingCharacters(in: .whitespaces)
        Task {
            await filterVM.applyFilters(page: 1, per: 20)
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .foregroundStyle(isSelected ? .blue : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .init(frame.size))
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), frames)
    }
}

#Preview {
    @Previewable @State var selection: Manga? = nil
    MacSearchView(selection: $selection)
        .frame(width: 600, height: 800)
}
