//
//  VisionExploreView.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 18/02/26.
//

import SwiftUI

struct VisionExploreView: View {
    @Environment(MangaViewModel.self) private var mangaVM
    @State private var searchText = ""

    private let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 350), spacing: 40)
    ]

    var body: some View {
        VisionExploreContent(mangaVM: mangaVM, columns: columns)
            .navigationTitle("nav_explore")
            .navigationDestination(for: Manga.self) { manga in
                VisionExploreDetailView(manga: manga)
            }
            .searchable(text: $searchText, prompt: "search_placeholder")
            .onSubmit(of: .search) {
                Task {
                    await mangaVM.searchMangas(text: searchText)
                }
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty {
                    Task {
                        await mangaVM.fetchMangas()
                    }
                }
            }
            .task {
                if mangaVM.mangas.isEmpty {
                    await mangaVM.fetchMangas()
                }
            }
            .refreshable {
                await mangaVM.fetchMangas()
            }
    }
}

// MARK: - Explore Content (extracted to help compiler)
struct VisionExploreContent: View {
    let mangaVM: MangaViewModel
    let columns: [GridItem]

    var body: some View {
        ZStack {
            if mangaVM.isLoading && mangaVM.mangas.isEmpty {
                ProgressView("loading_mangas")
                    .font(.title2)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 40) {
                        ForEach(mangaVM.mangas) { manga in
                            NavigationLink(value: manga) {
                                VisionMangaCard(manga: manga)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(60)
                }
            }
        }
    }
}

// MARK: - Best Mangas View
struct VisionBestMangasView: View {
    @Environment(MangaViewModel.self) private var mangaVM

    private let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 350), spacing: 40)
    ]

    var body: some View {
        VisionBestMangasContent(mangaVM: mangaVM, columns: columns)
            .navigationTitle("best_mangas_title")
            .navigationDestination(for: Manga.self) { manga in
                VisionExploreDetailView(manga: manga)
            }
            .task {
                if mangaVM.mangas.isEmpty {
                    await mangaVM.fetchBestMangas()
                }
            }
            .refreshable {
                await mangaVM.fetchBestMangas()
            }
    }
}

// MARK: - Best Mangas Content (extracted to help compiler)
struct VisionBestMangasContent: View {
    let mangaVM: MangaViewModel
    let columns: [GridItem]

    var body: some View {
        ZStack {
            if mangaVM.isLoading && mangaVM.mangas.isEmpty {
                ProgressView("loading_mangas")
                    .font(.title2)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 40) {
                        ForEach(mangaVM.mangas) { manga in
                            NavigationLink(value: manga) {
                                VisionMangaCard(manga: manga)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(60)
                }
            }
        }
    }
}

#Preview {
    VisionExploreView()
        .environment(MangaViewModel())
}
