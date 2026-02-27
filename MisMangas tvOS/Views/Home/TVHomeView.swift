//
//  TVHomeView.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 22/2/26.
//

import SwiftUI

struct TVHomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 60) {
                // MARK: - Hero Carousel
                if !viewModel.bestMangas.isEmpty {
                    TVHeroCarousel(mangas: Array(viewModel.bestMangas.prefix(10)))
                }

                // Secciones por demografía
                ForEach(DemographicsConfig.list) { config in
                    if let mangas = viewModel.mangasByDemographic[config.id], !mangas.isEmpty {
                        TVHorizontalSection(
                            title: config.title,
                            icon: config.icon,
                            color: config.color
                        ) {
                            ForEach(mangas) { manga in
                                NavigationLink(value: manga) {
                                    TVExploreCardLabel(manga: manga)
                                }
                                .buttonStyle(.card)
                            }
                        }
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.vertical, 50)
        }
        .navigationTitle("nav_home")
        .navigationDestination(for: Manga.self) { manga in
            TVMangaPreviewView(manga: manga)
        }
        .task {
            await viewModel.loadAll()
        }
        .overlay {
            if viewModel.state.isLoading && viewModel.bestMangas.isEmpty {
                ProgressView("loading_mangas")
                    .font(.title)
            }
        }
    }
}

#Preview {
    let authVM = AuthViewModel()
    return TVHomeView()
        .environment(authVM)
        .environment(CloudCollectionViewModel(authVM: authVM))
        .environment(TranslationService())
}
