//
//  HomeView.swift
//  MisMangas
//
//  Created by Juan Carlos on 2/2/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var filterVM = MangaViewModel()
    @State private var showFilters = false
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
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    if filterVM.filters.isActive {
                        // Resultados filtrados
                        filteredContent
                    } else {
                        // Contenido normal por demografía
                        if !viewModel.bestMangas.isEmpty {
                            heroCarousel
                        }

                        ForEach(demographicConfig, id: \.key) { config in
                            if let mangas = viewModel.mangasByDemographic[config.key], !mangas.isEmpty {
                                section(title: config.title, icon: config.icon, color: config.color, mangas: mangas)
                            }
                        }
                    }

                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("nav_home")
            .navigationDestination(for: Manga.self) { manga in
                MangaDetailView(manga: manga, namespace: namespace)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                        .foregroundStyle(filterVM.filters.isActive ? .blue : .primary)
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterView(filters: $filterVM.filters)
            }
            .refreshable {
                if filterVM.filters.isActive {
                    await filterVM.applyFilters()
                } else {
                    await viewModel.loadAll()
                }
            }
            .onChange(of: filterVM.filters) { _, newFilters in
                Task {
                    if newFilters.isActive {
                        await filterVM.applyFilters()
                    }
                }
            }
        }
        .task {
            await viewModel.loadAll()
        }
    }

    // MARK: - Filtered Content

    @ViewBuilder
    private var filteredContent: some View {
        HStack {
            Label("section_filtered_results", systemImage: "line.3.horizontal.decrease")
                .font(.title3.bold())

            Text("(\(filterVM.mangas.count))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Button("action_clear_filters") {
                filterVM.filters.clear()
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)

        if filterVM.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 200)
        } else if filterVM.mangas.isEmpty {
            ContentUnavailableView("filter_no_results", systemImage: "magnifyingglass")
                .frame(minHeight: 200)
        } else {
            // Si filtró por UNA sola demografía, mostrar solo esa sección
            if filterVM.filters.demographics.count == 1,
               let selectedDemo = filterVM.filters.demographics.first,
               let config = demographicConfig.first(where: { $0.key == selectedDemo }) {
                section(title: config.title, icon: config.icon, color: config.color, mangas: filterVM.mangas)
            } else {
                // Agrupar por demografía
                ForEach(demographicConfig, id: \.key) { config in
                    let mangas = filterVM.mangas.filter { $0.demographics.contains { $0.demographic == config.key } }
                    if !mangas.isEmpty {
                        section(title: config.title, icon: config.icon, color: config.color, mangas: mangas)
                    }
                }

                // Sin demografía
                let other = filterVM.mangas.filter { $0.demographics.isEmpty }
                if !other.isEmpty {
                    section(title: "section_other", icon: "square.grid.2x2", color: .gray, mangas: other)
                }
            }
        }
    }

    // MARK: - Hero

    private var heroCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("section_best_rated", systemImage: "trophy.fill")
                .font(.title2.bold())
                .padding(.horizontal)

            TabView {
                ForEach(viewModel.bestMangas.prefix(5)) { manga in
                    NavigationLink(value: manga) {
                        HeroCard(manga: manga)
                    }
                    .buttonStyle(.plain)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 280)
        }
    }

    // MARK: - Section

    private func section(title: LocalizedStringKey, icon: String, color: Color, mangas: [Manga]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.title3.bold())
                .foregroundStyle(color)
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
}

// MARK: - Hero Card

struct HeroCard: View {
    let manga: Manga

    @State private var coverVM = MangaCoverVM()

    private var coverURL: URL? {
        URL(string: manga.mainPicture.replacingOccurrences(of: "\"", with: ""))
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Imagen con caché
            Group {
                if let image = coverVM.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(.gray.opacity(0.2))
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
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 8) {
                Text(manga.title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill").foregroundStyle(.yellow)
                    Text(String(format: "%.1f", manga.score)).fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundStyle(.white)
            }
            .padding()
        }
        .padding(.horizontal)
        .onAppear {
            coverVM.getImage(url: coverURL)
        }
    }
}

#Preview(traits: .sampleData) {
    HomeView()
}
