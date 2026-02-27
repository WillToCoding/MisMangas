//
//  VisionHomeView.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 18/02/26.
//

import SwiftUI

struct VisionHomeView: View {
    @Bindable var viewModel: HomeViewModel

    var body: some View {
        ZStack {
            if viewModel.state.isLoading && viewModel.bestMangas.isEmpty {
                ProgressView("loading_mangas")
                    .font(.title2)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 50) {
                        // Hero Carousel - Best Mangas
                        if !viewModel.bestMangas.isEmpty {
                            VisionHeroCarousel(mangas: Array(viewModel.bestMangas.prefix(10)))
                        }

                        // Secciones por demografía
                        ForEach(DemographicsConfig.list) { config in
                            if let mangas = viewModel.mangasByDemographic[config.id], !mangas.isEmpty {
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

#Preview {
    VisionHomeView(viewModel: HomeViewModel())
}
