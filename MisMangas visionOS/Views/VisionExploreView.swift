//
//  VisionHomeView.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 18/02/26.
//

import SwiftUI

// MARK: - Vision Home View
struct VisionHomeView: View {
    @Bindable var viewModel: HomeViewModel

    private let demographicConfig: [(key: String, title: LocalizedStringKey, icon: String, color: Color)] = [
        ("Shounen", "section_shounen", "flame.fill", .orange),
        ("Seinen", "section_seinen", "person.fill", .purple),
        ("Shoujo", "section_shoujo", "heart.fill", .pink),
        ("Josei", "section_josei", "sparkles", .indigo),
        ("Kids", "section_kids", "star.fill", .yellow)
    ]

    var body: some View {
        ZStack {
            if viewModel.state.isLoading && viewModel.bestMangas.isEmpty {
                ProgressView("loading_mangas")
                    .font(.title2)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 50) {
                        // Hero - Best Mangas
                        if !viewModel.bestMangas.isEmpty {
                            VisionHorizontalSection(
                                title: "section_best_rated",
                                icon: "trophy.fill",
                                color: .yellow
                            ) {
                                ForEach(Array(viewModel.bestMangas.prefix(10).enumerated()), id: \.element.id) { index, manga in
                                    NavigationLink(value: manga) {
                                        VisionRankedCard(manga: manga, rank: index + 1)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Secciones por demografía
                        ForEach(demographicConfig, id: \.key) { config in
                            if let mangas = viewModel.mangasByDemographic[config.key], !mangas.isEmpty {
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

                        Spacer(minLength: 60)
                    }
                    .padding(.vertical, 40)
                }
            }
        }
        .navigationTitle("nav_home")
        .navigationDestination(for: Manga.self) { manga in
            VisionExploreDetailView(manga: manga)
        }
        .task {
            await viewModel.loadAll()
        }
        .refreshable {
            await viewModel.loadAll()
        }
    }
}

// MARK: - Vision Search View
struct VisionSearchView: View {
    @Environment(MangaViewModel.self) private var viewModel
    @State private var searchText = ""
    @State private var filters = MangaFilters()
    @State private var hasSearched = false
    @State private var showFilters = false

    private let demographicConfig: [(key: String, title: LocalizedStringKey, icon: String, color: Color)] = [
        ("Shounen", "section_shounen", "flame.fill", .orange),
        ("Seinen", "section_seinen", "person.fill", .purple),
        ("Shoujo", "section_shoujo", "heart.fill", .pink),
        ("Josei", "section_josei", "sparkles", .indigo),
        ("Kids", "section_kids", "star.fill", .yellow)
    ]

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
            LazyVStack(alignment: .leading, spacing: 40) {
                // Search Controls
                HStack(spacing: 20) {
                    // Search field
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

                    // Filter button
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

                    // Search button
                    Button {
                        performSearch()
                    } label: {
                        Label("action_search", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(searchText.trimmingCharacters(in: .whitespaces).isEmpty && !filters.isActive)
                }
                .padding(.horizontal, 60)

                // Active filters pills
                if activeFiltersCount > 0 {
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

                // Results
                if viewModel.state.isLoading {
                    HStack {
                        Spacer()
                        ProgressView("searching")
                            .font(.title2)
                        Spacer()
                    }
                    .padding(.top, 60)
                } else if hasSearched && viewModel.mangas.isEmpty {
                    ContentUnavailableView(
                        "filter_no_results",
                        systemImage: "magnifyingglass",
                        description: Text("search_try_another")
                    )
                    .padding(.top, 60)
                } else if !viewModel.mangas.isEmpty {
                    // Resultados agrupados por demografía
                    ForEach(demographicConfig, id: \.key) { config in
                        if let mangas = mangasByDemographic[config.key], !mangas.isEmpty {
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

                    // Mangas sin demografía
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
                } else {
                    // Estado inicial
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

                Spacer(minLength: 60)
            }
            .padding(.vertical, 40)
        }
        .navigationTitle("nav_search")
        .navigationDestination(for: Manga.self) { manga in
            VisionExploreDetailView(manga: manga)
        }
        .sheet(isPresented: $showFilters) {
            VisionFilterView(filters: $filters)
        }
        .onChange(of: showFilters) { wasShowing, isShowing in
            if wasShowing && !isShowing && filters.isActive {
                performSearch()
            }
        }
    }

    private func performSearch() {
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

// MARK: - Vision Filter Pill
struct VisionFilterPill: View {
    let text: String
    let color: Color
    let onRemove: () -> Void

    var body: some View {
        Button {
            onRemove()
        } label: {
            HStack(spacing: 6) {
                Text(text)
                Image(systemName: "xmark.circle.fill")
            }
            .font(.callout)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.2), in: Capsule())
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Vision Filter View
struct VisionFilterView: View {
    @Binding var filters: MangaFilters
    @Environment(\.dismiss) private var dismiss

    // Datos estáticos para filtros (evita dependencia de FilterViewModel)
    private let availableDemographics = ["Shounen", "Seinen", "Shoujo", "Josei", "Kids"]
    private let availableGenres = ["Action", "Adventure", "Comedy", "Drama", "Fantasy", "Horror", "Mystery", "Romance", "Sci-Fi", "Slice of Life", "Sports", "Supernatural"]
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                        // Demografías
                        filterSection(title: "filter_demographics", icon: "person.3.fill", color: .purple) {
                            VisionChipGroup(
                                items: availableDemographics,
                                selection: $filters.demographics,
                                color: .purple
                            )
                        }

                        // Géneros
                        filterSection(title: "filter_genres", icon: "tag.fill", color: .blue) {
                            VisionChipGroup(
                                items: availableGenres,
                                selection: $filters.genres,
                                color: .blue
                            )
                        }

                        // Score mínimo
                        filterSection(title: "filter_min_score", icon: "star.fill", color: .yellow) {
                            HStack(spacing: 12) {
                                ForEach([nil, 7.0, 7.5, 8.0, 8.5, 9.0], id: \.self) { score in
                                    Button {
                                        filters.minScore = score
                                    } label: {
                                        Text(score == nil ? "Any" : "≥ \(score!.formatted(.number.precision(.fractionLength(1))))")
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                filters.minScore == score ? Color.yellow : Color.yellow.opacity(0.2),
                                                in: Capsule()
                                            )
                                            .foregroundStyle(filters.minScore == score ? .black : .yellow)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Estado
                        filterSection(title: "filter_status", icon: "clock.fill", color: .green) {
                            HStack(spacing: 12) {
                                Button {
                                    filters.status = nil
                                } label: {
                                    Text("Any")
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            filters.status == nil ? Color.green : Color.green.opacity(0.2),
                                            in: Capsule()
                                        )
                                        .foregroundStyle(filters.status == nil ? .white : .green)
                                }
                                .buttonStyle(.plain)

                                ForEach([MangaStatus.publishing, .complete, .hiatus], id: \.self) { status in
                                    Button {
                                        filters.status = status
                                    } label: {
                                        Text(status.localizedName)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                filters.status == status ? Color.green : Color.green.opacity(0.2),
                                                in: Capsule()
                                            )
                                            .foregroundStyle(filters.status == status ? .white : .green)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Botones de acción
                        HStack(spacing: 20) {
                            if filters.isActive {
                                Button {
                                    filters.clear()
                                } label: {
                                    Label("action_clear_filters", systemImage: "xmark.circle.fill")
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }

                            Button {
                                dismiss()
                            } label: {
                                Label("action_apply_filters", systemImage: "checkmark.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.top, 20)
                }
                .padding(40)
            }
            .navigationTitle("nav_filter")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func filterSection<Content: View>(
        title: LocalizedStringKey,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: icon)
                .font(.title2.bold())
                .foregroundStyle(color)

            content()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Vision Chip Group
struct VisionChipGroup: View {
    let items: [String]
    @Binding var selection: Set<String>
    let color: Color

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(items, id: \.self) { item in
                    Button {
                        if selection.contains(item) {
                            selection.remove(item)
                        } else {
                            selection.insert(item)
                        }
                    } label: {
                        Text(localizedAPIValue(item))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selection.contains(item) ? color : color.opacity(0.2),
                                in: Capsule()
                            )
                            .foregroundStyle(selection.contains(item) ? .white : color)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Vision Explore Card
struct VisionExploreCard: View {
    let manga: Manga
    @State private var coverVM = MangaCoverVM()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Portada
            Group {
                if let image = coverVM.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .overlay {
                            if coverVM.isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
            }
            .frame(width: 200, height: 300)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(manga.title)
                    .font(.headline)
                    .lineLimit(2)
                    .frame(width: 200, alignment: .leading)

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(manga.score.formatted(.number.precision(.fractionLength(1))))
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .task {
            coverVM.getImage(url: manga.coverURL)
        }
    }
}

// MARK: - Vision Ranked Card
struct VisionRankedCard: View {
    let manga: Manga
    let rank: Int
    @State private var coverVM = MangaCoverVM()

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 16) {
                // Portada
                Group {
                    if let image = coverVM.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(.gray.opacity(0.3))
                            .overlay {
                                if coverVM.isLoading {
                                    ProgressView()
                                } else {
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                }
                            }
                    }
                }
                .frame(width: 200, height: 300)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(manga.title)
                        .font(.headline)
                        .lineLimit(2)
                        .frame(width: 200, alignment: .leading)

                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text(manga.score.formatted(.number.precision(.fractionLength(1))))
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }

            // Rank badge
            Text("#\(rank)")
                .font(.headline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.yellow.gradient, in: Capsule())
                .padding(8)
        }
        .task {
            coverVM.getImage(url: manga.coverURL)
        }
    }
}

#Preview {
    VisionHomeView(viewModel: HomeViewModel())
}
