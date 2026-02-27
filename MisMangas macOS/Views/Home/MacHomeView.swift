//
//  MacHomeView.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 22/2/26.
//

import SwiftUI

struct MacHomeView: View {
    @Binding var selection: Manga?

    @State private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                normalContent

                Spacer(minLength: 50)
            }
            .padding(.vertical)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("nav_home")
        .toolbar {
            ToolbarItem {
                Button {
                    Task {
                        await viewModel.loadAll()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("action_refresh")
            }
        }
        .task {
            await viewModel.loadAll()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshContent)) { _ in
            Task {
                await viewModel.loadAll()
            }
        }
        .overlay {
            if viewModel.state.isLoading && viewModel.bestMangas.isEmpty {
                ProgressView("loading_mangas")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Normal Content

    private var normalContent: some View {
        Group {
            // Hero carousel con los mejores mangas
            if !viewModel.bestMangas.isEmpty {
            MacHorizontalSection(
                title: "section_best_rated",
                icon: "trophy.fill",
                color: .yellow,
                itemCount: min(10, viewModel.bestMangas.count)
            ) {
                ForEach(Array(viewModel.bestMangas.prefix(10).enumerated()), id: \.element.id) { index, manga in
                    MacHeroCard(manga: manga, rank: index + 1)
                        .id(index)
                        .onTapGesture {
                            selection = manga
                        }
                }
            }
        }

        // Secciones por demografía
        ForEach(DemographicsConfig.list) { config in
            if let mangas = viewModel.mangasByDemographic[config.id], !mangas.isEmpty {
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
        }
    }

}

// MARK: - Horizontal Section with Navigation Buttons

struct MacHorizontalSection<Content: View>: View {
    let title: LocalizedStringKey
    let icon: String
    let color: Color
    let itemCount: Int
    @ViewBuilder let content: () -> Content

    @State private var currentIndex = 0

    private var canGoBack: Bool { currentIndex > 0 }
    private var canGoForward: Bool { currentIndex < itemCount - 1 }

    var body: some View {
        VStack(spacing: 12) {
            // Header con título
            HStack {
                Label(title, systemImage: icon)
                    .font(.title3.bold())
                    .foregroundStyle(color)
                Spacer()
            }
            .padding(.horizontal, 20)

            // ScrollView con scroll programático
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        content()
                    }
                    .padding(.horizontal, 20)
                }
                .onChange(of: currentIndex) { _, newIndex in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(newIndex, anchor: .leading)
                    }
                }
            }

            // Botones de navegación centrados abajo
            if itemCount > 1 {
                HStack(spacing: 16) {
                    Button {
                        currentIndex = max(0, currentIndex - 1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canGoBack)

                    // Indicador de posición
                    Text("\(currentIndex + 1) / \(itemCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(minWidth: 50)

                    Button {
                        currentIndex = min(itemCount - 1, currentIndex + 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.headline)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canGoForward)
                }
            }
        }
    }
}

// MARK: - Hero Card

struct MacHeroCard: View {
    let manga: Manga
    var rank: Int = 0

    @State private var coverVM = MangaCoverVM()

    private var coverURL: URL? { manga.coverURL }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Imagen
            Group {
                if let image = coverVM.image {
                    Image(nsImage: image)
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
            .frame(width: 280, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Gradiente
            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            // Rank badge
            if rank > 0 {
                Text("#\(rank)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.yellow.gradient, in: Capsule())
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(manga.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(manga.score.formatted(.number.precision(.fractionLength(1))))
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundStyle(.white)
            }
            .padding(12)
        }
        .frame(width: 280, height: 180)
        .contentShape(Rectangle())
        .task(id: coverURL) {
            coverVM.image = nil
            coverVM.getImage(url: coverURL)
        }
    }
}

#Preview {
    @Previewable @State var selection: Manga? = nil
    MacHomeView(selection: $selection)
        .frame(width: 600, height: 800)
}
