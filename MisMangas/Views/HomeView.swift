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
    @Namespace private var namespace

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    if !viewModel.bestMangas.isEmpty {
                        heroCarousel
                    }

                    ForEach(DemographicsConfig.list, id: \.key) { config in
                        if let mangas = viewModel.mangasByDemographic[config.key], !mangas.isEmpty {
                            section(title: config.title, icon: config.icon, color: config.color, mangas: mangas)
                        }
                    }

                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("nav_home")
            .navigationDestination(for: Manga.self) { manga in
                MangaDetailView(manga: manga, namespace: namespace)
            }
            .refreshable {
                await viewModel.loadAll()
            }
        }
        .task {
            await viewModel.loadAll()
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

    private var coverURL: URL? { manga.coverURL }

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
                    Text(manga.score.formatted(.number.precision(.fractionLength(1)))).fontWeight(.semibold)
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
