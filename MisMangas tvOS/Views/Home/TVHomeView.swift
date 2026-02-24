//
//  TVHomeView.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 22/2/26.
//

import SwiftUI

struct TVHomeView: View {
    @State private var viewModel = HomeViewModel()

    private let demographicConfig: [(key: String, title: LocalizedStringKey, icon: String, color: Color)] = [
        ("Shounen", "section_shounen", "flame.fill", .orange),
        ("Seinen", "section_seinen", "person.fill", .purple),
        ("Shoujo", "section_shoujo", "heart.fill", .pink),
        ("Josei", "section_josei", "sparkles", .indigo),
        ("Kids", "section_kids", "star.fill", .yellow)
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 60) {
                // Best Mangas
                if !viewModel.bestMangas.isEmpty {
                    TVHorizontalSection(
                        title: "section_best_rated",
                        icon: "trophy.fill",
                        color: .yellow
                    ) {
                        ForEach(Array(viewModel.bestMangas.prefix(10).enumerated()), id: \.element.id) { index, manga in
                            NavigationLink(value: manga) {
                                TVHeroCardLabel(manga: manga, rank: index + 1)
                            }
                            .buttonStyle(.card)
                        }
                    }
                }

                // Secciones por demografía
                ForEach(demographicConfig, id: \.key) { config in
                    if let mangas = viewModel.mangasByDemographic[config.key], !mangas.isEmpty {
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

// MARK: - Horizontal Section

struct TVHorizontalSection<Content: View>: View {
    let title: LocalizedStringKey
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            Label(title, systemImage: icon)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(color)
                .padding(.horizontal, 80)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 40) {
                    content()
                }
                .padding(.horizontal, 80)
                .padding(.vertical, 20) // Espacio para el efecto de escala del foco
            }
            .focusSection()
        }
    }
}

// MARK: - Hero Card Label

struct TVHeroCardLabel: View {
    let manga: Manga
    var rank: Int = 0

    @State private var coverVM = MangaCoverVM()

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Imagen
            Group {
                if let image = coverVM.image {
                    #if os(tvOS)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    #endif
                } else {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .overlay {
                            if coverVM.isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
            }
            .frame(width: 500, height: 300)
            .clipped()

            // Gradiente
            LinearGradient(
                colors: [.clear, .black.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Rank
            if rank > 0 {
                Text("#\(rank)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.yellow.gradient, in: Capsule())
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            // Info
            VStack(alignment: .leading, spacing: 10) {
                Text(manga.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(manga.score.formatted(.number.precision(.fractionLength(1))))
                        .fontWeight(.semibold)
                    if let volumes = manga.volumes {
                        Text("•")
                        Text("\(volumes) vols")
                    }
                }
                .font(.system(size: 24))
                .foregroundStyle(.white.opacity(0.9))
            }
            .padding(24)
        }
        .frame(width: 500, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .task {
            coverVM.getImage(url: manga.coverURL)
        }
    }
}

// MARK: - Explore Card Label

struct TVExploreCardLabel: View {
    let manga: Manga

    @State private var coverVM = MangaCoverVM()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Portada
            Group {
                if let image = coverVM.image {
                    #if os(tvOS)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    #endif
                } else {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .overlay {
                            if coverVM.isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
            }
            .frame(width: 250, height: 375)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(manga.title)
                    .font(.system(size: 24, weight: .bold))
                    .lineLimit(2)
                    .frame(width: 250, alignment: .leading)

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(manga.score.formatted(.number.precision(.fractionLength(1))))
                        .fontWeight(.medium)
                }
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
            }
        }
        .task {
            coverVM.getImage(url: manga.coverURL)
        }
    }
}

// MARK: - Manga Preview View

struct TVMangaPreviewView: View {
    let manga: Manga

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    @State private var coverVM = MangaCoverVM()
    @State private var isAdding = false
    @State private var showAddedConfirmation = false
    @State private var showFullSynopsis = false

    private var isInCollection: Bool {
        cloudVM.cloudCollection.contains { $0.manga.id == manga.id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 50) {
                // Botones de acción arriba
                HStack(spacing: 30) {
                    Button {
                        dismiss()
                    } label: {
                        Label("action_back", systemImage: "chevron.left")
                            .font(.system(size: 28, weight: .semibold))
                    }
                    .buttonStyle(.bordered)

                    if authVM.isAuthenticated {
                        if isInCollection {
                            Label("collection_already_added", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.green)
                        } else {
                            Button {
                                addToCollection()
                            } label: {
                                if isAdding {
                                    ProgressView()
                                } else {
                                    Label("action_add_collection", systemImage: "plus.circle.fill")
                                        .font(.system(size: 28, weight: .semibold))
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isAdding)
                        }
                    }
                }
                .focusSection()

                // Contenido principal
                HStack(alignment: .top, spacing: 80) {
                    // Portada
                    Group {
                        if let image = coverVM.image {
                            #if os(tvOS)
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            #endif
                        } else {
                            Rectangle()
                                .fill(.gray.opacity(0.3))
                                .overlay { ProgressView() }
                        }
                    }
                    .frame(width: 400, height: 600)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 20)

                    // Info
                    VStack(alignment: .leading, spacing: 30) {
                        Text(manga.title)
                            .font(.system(size: 56, weight: .bold))

                        if let titleJapanese = manga.titleJapanese {
                            Text(titleJapanese)
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                        }

                        // Stats
                        HStack(spacing: 40) {
                            Label(manga.score.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
                                .foregroundStyle(.yellow)
                            if let volumes = manga.volumes {
                                Label("\(volumes) vols", systemImage: "book.closed")
                            }
                            if let chapters = manga.chapters {
                                Label("\(chapters) caps", systemImage: "doc.text")
                            }
                            Label(manga.status.capitalized, systemImage: "clock")
                        }
                        .font(.system(size: 28, weight: .medium))

                        // Géneros
                        if !manga.genres.isEmpty {
                            FlowLayout(spacing: 12) {
                                ForEach(manga.genres.prefix(6)) { genre in
                                    Text(genre.genre)
                                        .font(.system(size: 22))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(.blue.opacity(0.2), in: Capsule())
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 900, alignment: .leading)
                }

                // Sinopsis expandible
                if let synopsis = manga.sypnosis, !synopsis.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("detail_synopsis")
                            .font(.system(size: 36, weight: .bold))

                        Text(synopsis)
                            .font(.system(size: 26))
                            .lineLimit(showFullSynopsis ? nil : 6)
                            .foregroundStyle(.secondary)

                        if synopsis.count > 300 {
                            Button {
                                withAnimation {
                                    showFullSynopsis.toggle()
                                }
                            } label: {
                                Label(
                                    showFullSynopsis ? "action_show_less" : "action_show_more",
                                    systemImage: showFullSynopsis ? "chevron.up" : "chevron.down"
                                )
                                .font(.system(size: 24, weight: .medium))
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(40)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
                    .focusSection()
                }

                Spacer(minLength: 100)
            }
            .padding(80)
        }
        .navigationTitle(manga.title)
        .task {
            coverVM.getImage(url: manga.coverURL)
        }
        .overlay(alignment: .top) {
            if showAddedConfirmation {
                Text("collection_added_success")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 16)
                    .background(.green, in: Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 50)
            }
        }
        .animation(.spring, value: showAddedConfirmation)
        .onExitCommand {
            dismiss()
        }
    }

    private func addToCollection() {
        isAdding = true
        Task {
            do {
                try await cloudVM.addToCollection(
                    manga: manga,
                    volumesOwned: [1],
                    readingVolume: 1,
                    completeCollection: false
                )
                showAddedConfirmation = true
                try? await Task.sleep(for: .seconds(2))
                showAddedConfirmation = false
            } catch {
                print("Error adding to collection: \(error)")
            }
            isAdding = false
        }
    }
}

#Preview {
    let authVM = AuthViewModel()
    return TVHomeView()
        .environment(authVM)
        .environment(CloudCollectionViewModel(authVM: authVM))
}
