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

                    ForEach(DemographicsConfig.list) { config in
                        if let mangas = viewModel.mangasByDemographic[config.id], !mangas.isEmpty {
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

    @State private var currentHeroIndex = 0

    private var heroCarousel: some View {
        let heroMangas = Array(viewModel.bestMangas.prefix(5))

        return VStack(alignment: .leading, spacing: 12) {
            Label("section_best_rated", systemImage: "trophy.fill")
                .font(.title2.bold())
                .padding(.horizontal)
                .accessibilityHeader(.h2)

            TabView(selection: $currentHeroIndex) {
                ForEach(Array(heroMangas.enumerated()), id: \.element.id) { index, manga in
                    NavigationLink(value: manga) {
                        HeroCard(manga: manga)
                    }
                    .buttonStyle(.plain)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 280)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(heroAccessibilityLabel(for: heroMangas))
            .accessibilityValue(String(localized: "accessibility_page_of \(currentHeroIndex + 1) \(heroMangas.count)"))
            .accessibilityHint(String(localized: "accessibility_double_tap_details"))
            .accessibilityAddTraits(.isButton)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    if currentHeroIndex < heroMangas.count - 1 {
                        currentHeroIndex += 1
                    }
                case .decrement:
                    if currentHeroIndex > 0 {
                        currentHeroIndex -= 1
                    }
                @unknown default:
                    break
                }
            }
        }
    }

    // MARK: - Section

    private func section(title: LocalizedStringKey, icon: String, color: Color, mangas: [Manga]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.title3.bold())
                .foregroundStyle(color)
                .padding(.horizontal)
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

    // MARK: - Accessibility

    private func heroAccessibilityLabel(for mangas: [Manga]) -> String {
        guard currentHeroIndex < mangas.count else { return "" }
        let manga = mangas[currentHeroIndex]
        let score = String(localized: "accessibility_score \(manga.score.formatted(.number.precision(.fractionLength(1))))")
        return "\(manga.title), \(score)"
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
            .accessibilityHidden(true)

            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(manga.title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill").foregroundStyle(.yellow)
                        .accessibilityHidden(true)
                    Text(manga.score.formatted(.number.precision(.fractionLength(1)))).fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundStyle(.white)
            }
            .padding()
        }
        .padding(.horizontal)
        .accessibilityCard(
            label: manga.title,
            value: String(localized: "accessibility_score \(manga.score.formatted(.number.precision(.fractionLength(1))))"),
            hint: String(localized: "accessibility_double_tap_details")
        )
        .onAppear {
            coverVM.getImage(url: coverURL)
        }
    }
}

#Preview(traits: .sampleData) {
    HomeView()
}
