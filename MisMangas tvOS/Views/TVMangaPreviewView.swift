//
//  TVMangaPreviewView.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 25/2/26.
//

import SwiftUI
import SwiftData

struct TVMangaPreviewView: View {
    let manga: Manga

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(TranslationService.self) private var translationService

    @Query private var localCollection: [UserCollection]

    @State private var viewModel: MangaDetailViewModel
    @State private var coverVM = MangaCoverVM()
    @State private var isAdding = false
    @State private var showAddedConfirmation = false
    @State private var showFullSynopsis = false

    init(manga: Manga) {
        self.manga = manga
        _viewModel = State(initialValue: MangaDetailViewModel(manga: manga))
    }

    private var isInLocalCollection: Bool {
        localCollection.contains { $0.manga.id == manga.id }
    }

    private var isInCloudCollection: Bool {
        cloudVM.cloudCollection.contains { $0.manga.id == manga.id }
    }

    private var isInCollection: Bool {
        isInCloudCollection || isInLocalCollection
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 50) {
                actionButtons
                contentSection
                synopsisSection
                relatedSection
                Spacer(minLength: 100)
            }
            .padding(80)
        }
        .navigationTitle(manga.title)
        .navigationDestination(item: $viewModel.selectedRelatedManga) { relatedManga in
            TVMangaPreviewView(manga: relatedManga)
        }
        .task {
            coverVM.getImage(url: manga.coverURL)
            viewModel.configure(translationService: translationService)
            await viewModel.loadAllData()
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

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 30) {
            Button {
                dismiss()
            } label: {
                Label("action_back", systemImage: "chevron.left")
                    .font(.system(size: 28, weight: .semibold))
            }
            .buttonStyle(.bordered)

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
        .focusSection()
    }

    // MARK: - Content Section

    private var contentSection: some View {
        HStack(alignment: .top, spacing: 80) {
            // Portada
            Group {
                if let image = coverVM.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
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
    }

    // MARK: - Synopsis Section

    @ViewBuilder
    private var synopsisSection: some View {
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
    }

    // MARK: - Related Section

    private var relatedSection: some View {
        TVRelatedMangasSection(
            relatedMangas: viewModel.relatedMangas,
            relatedMangaDetails: viewModel.relatedMangaDetails,
            recommendations: viewModel.recommendations,
            isLoading: viewModel.isLoadingRelated,
            onMangaTap: { id in
                Task { await viewModel.loadAndNavigateToManga(id: id) }
            }
        )
    }

    // MARK: - Actions

    private func addToCollection() {
        isAdding = true
        Task {
            // 1. Guardar en local (siempre)
            let dataContainer = DataContainer(modelContainer: modelContext.container)
            do {
                try await dataContainer.addToCollection(
                    manga: manga,
                    volumesOwned: [1],
                    currentReadingVolume: 1,
                    hasCompleteCollection: false
                )
            } catch {
                print("Error saving to local: \(error)")
                isAdding = false
                return
            }

            // 2. Si está logueado, también guardar en cloud
            if authVM.isAuthenticated {
                do {
                    try await cloudVM.addToCollection(
                        manga: manga,
                        volumesOwned: [1],
                        readingVolume: 1,
                        completeCollection: false
                    )
                } catch {
                    print("Error saving to cloud: \(error)")
                }
            }

            showAddedConfirmation = true
            try? await Task.sleep(for: .seconds(2))
            showAddedConfirmation = false
            isAdding = false
        }
    }
}

#Preview {
    let authVM = AuthViewModel()
    NavigationStack {
        TVMangaPreviewView(manga: .test)
    }
    .environment(authVM)
    .environment(CloudCollectionViewModel(authVM: authVM))
    .environment(TranslationService())
    .modelContainer(for: [MangaModel.self, UserCollection.self, OwnedVolume.self], inMemory: true)
}
