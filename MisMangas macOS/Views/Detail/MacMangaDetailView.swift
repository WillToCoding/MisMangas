//
//  MacMangaDetailView.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI
import SwiftData

struct MacMangaDetailView: View {
    let manga: Manga

    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(AuthViewModel.self) private var authVM
    @Environment(TranslationService.self) private var translationService

    @State private var viewModel: MangaDetailViewModel
    @State private var showAddToCollection = false
    @State private var showEditCollection = false

    init(manga: Manga) {
        self.manga = manga
        _viewModel = State(initialValue: MangaDetailViewModel(manga: manga))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header con imagen y datos principales
                HStack(alignment: .top, spacing: 24) {
                    // Portada
                    CachedCoverImage(
                        url: manga.coverURL,
                        width: 250,
                        height: 375
                    )
                    .shadow(radius: 8)

                    // Información principal
                    VStack(alignment: .leading, spacing: 16) {
                        Text(manga.title)
                            .font(.largeTitle.bold())

                        if let english = manga.titleEnglish {
                            Text(english)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }

                        if let japanese = manga.titleJapanese {
                            Text(japanese)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        // Stats
                        HStack(spacing: 24) {
                            VStack(alignment: .leading) {
                                Text("detail_score")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                    Text(manga.score.formatted(.number.precision(.fractionLength(2))))
                                        .font(.title2.bold())
                                        .lineLimit(1)
                                        .fixedSize()
                                }
                            }

                            if let volumes = manga.volumes {
                                VStack(alignment: .leading) {
                                    Text("detail_volumes")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(volumes)")
                                        .font(.title2.bold())
                                }
                            }

                            if let chapters = manga.chapters {
                                VStack(alignment: .leading) {
                                    Text("detail_chapters")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(chapters)")
                                        .font(.title2.bold())
                                }
                            }

                            VStack(alignment: .leading) {
                                Text("detail_status")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(manga.status == "finished" ? String(localized: "status_finished") : String(localized: "status_publishing"))
                                    .font(.headline)
                                    .foregroundStyle(manga.status == "finished" ? .green : .blue)
                            }
                        }

                        Divider()

                        // Botón de acción
                        if authVM.isAuthenticated && cloudVM.isInCollection(manga.id) {
                            Button {
                                showEditCollection = true
                            } label: {
                                Label("detail_edit_collection", systemImage: "pencil.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        } else {
                            Button {
                                showAddToCollection = true
                            } label: {
                                Label("detail_add_to_collection", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                    }
                }

                Divider()

                // Autores
                if !manga.authors.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("detail_authors")
                            .font(.title2.bold())

                        ForEach(manga.authors) { author in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(.blue)
                                    .font(.title3)

                                VStack(alignment: .leading) {
                                    Text("\(author.firstName) \(author.lastName)")
                                        .font(.headline)
                                    Text(author.role)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                // Géneros, temas, demografía
                if !manga.genres.isEmpty || !manga.themes.isEmpty || !manga.demographics.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("mac_categories")
                            .font(.title2.bold())

                        if !manga.genres.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("detail_genres")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                WrappingHStack(items: manga.genres.map { localizedAPIValue($0.genre) }, color: .blue)
                            }
                        }

                        if !manga.themes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("detail_themes")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                WrappingHStack(items: manga.themes.map { localizedAPIValue($0.theme) }, color: .purple)
                            }
                        }

                        if !manga.demographics.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("detail_demographics")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                WrappingHStack(items: manga.demographics.map { localizedAPIValue($0.demographic) }, color: .green)
                            }
                        }
                    }
                }

                // Personajes
                VStack(alignment: .leading, spacing: 12) {
                    Text("detail_characters")
                        .font(.title2.bold())

                    if viewModel.isLoadingCharacters {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical)
                    } else if viewModel.characters.isEmpty {
                        Text("detail_characters_empty")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 16) {
                                ForEach(viewModel.characters) { characterData in
                                    VStack(spacing: 8) {
                                        CachedCoverImage(
                                            url: URL(string: characterData.character.images.jpg.imageUrl),
                                            width: 100,
                                            height: 130
                                        )

                                        Text(characterData.character.name)
                                            .font(.caption)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                            .frame(width: 100)

                                        Text(characterData.role)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .frame(height: 180)
                    }
                }

                // Mangas Relacionados
                VStack(alignment: .leading, spacing: 12) {
                    Text("detail_related_mangas")
                        .font(.title2.bold())

                    if viewModel.isLoadingRelated {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical)
                    } else if viewModel.relatedMangas.isEmpty && viewModel.recommendations.isEmpty {
                        Text("detail_related_empty")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        // Relaciones directas
                        ForEach(viewModel.relatedMangas) { relation in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(localizedRelationType(relation.relation))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                ScrollView(.horizontal) {
                                    HStack(spacing: 16) {
                                        ForEach(relation.entry.filter { $0.type == "manga" }) { entry in
                                            Button {
                                                Task {
                                                    await viewModel.loadAndNavigateToManga(id: entry.malId)
                                                }
                                            } label: {
                                                VStack(spacing: 6) {
                                                    if let mangaDetail = viewModel.relatedMangaDetails[entry.malId] {
                                                        CachedCoverImage(
                                                            url: mangaDetail.coverURL,
                                                            width: 80,
                                                            height: 110
                                                        )
                                                    } else {
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(Color.gray.opacity(0.2))
                                                            .frame(width: 80, height: 110)
                                                            .overlay {
                                                                ProgressView()
                                                            }
                                                    }

                                                    Text(entry.name)
                                                        .font(.caption)
                                                        .lineLimit(2)
                                                        .multilineTextAlignment(.center)
                                                        .frame(width: 80)
                                                        .foregroundStyle(.primary)
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }

                        // Recomendaciones
                        if !viewModel.recommendations.isEmpty {
                            Text("detail_recommendations")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 12)

                            ScrollView(.horizontal) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.recommendations.prefix(10)) { rec in
                                        Button {
                                            Task {
                                                await viewModel.loadAndNavigateToManga(id: rec.entry.malId)
                                            }
                                        } label: {
                                            VStack(spacing: 6) {
                                                CachedCoverImage(
                                                    url: URL(string: rec.entry.images.jpg.imageUrl),
                                                    width: 80,
                                                    height: 110
                                                )

                                                Text(rec.entry.title)
                                                    .font(.caption)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.center)
                                                    .frame(width: 80)
                                                    .foregroundStyle(.primary)

                                                HStack(spacing: 4) {
                                                    Image(systemName: "hand.thumbsup.fill")
                                                        .font(.system(size: 10))
                                                    Text("\(rec.votes)")
                                                        .font(.system(size: 10))
                                                }
                                                .foregroundStyle(.secondary)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }

                // Sinopsis
                if let synopsis = manga.sypnosis {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("detail_synopsis")
                                .font(.title2.bold())

                            Spacer()

                            if viewModel.canTranslate {
                                if viewModel.isTranslating {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else if viewModel.translatedSynopsis != nil {
                                    Button {
                                        viewModel.toggleTranslation()
                                    } label: {
                                        Label(
                                            viewModel.showOriginal ? "translation_show_translated" : "translation_show_original",
                                            systemImage: "globe"
                                        )
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                        }

                        Text(viewModel.showOriginal ? synopsis : (viewModel.translatedSynopsis ?? synopsis))
                            .lineSpacing(6)
                    }
                }

                // Background
                if let background = manga.background {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("detail_background")
                            .font(.title2.bold())

                        Text(viewModel.showOriginal ? background : (viewModel.translatedBackground ?? background))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineSpacing(6)
                    }
                }
            }
            .padding(32)
        }
        .navigationTitle(manga.title)
        .sheet(isPresented: $showAddToCollection) {
            MacAddToCollectionView(manga: manga)
        }
        .sheet(isPresented: $showEditCollection) {
            if let collectionItem = cloudVM.getMangaCollection(manga.id) {
                MacEditCollectionView(collectionItem: collectionItem)
            }
        }
        .sheet(item: $viewModel.selectedRelatedManga) { relatedManga in
            NavigationStack {
                MacMangaDetailView(manga: relatedManga)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("action_close") {
                                viewModel.selectedRelatedManga = nil
                            }
                        }
                    }
            }
            .frame(minWidth: 800, minHeight: 600)
        }
        .task(id: manga.id) {
            viewModel.configure(translationService: translationService)
            await viewModel.loadAllData()
        }
    }

}

// MARK: - Wrapping HStack for tags
struct WrappingHStack: View {
    let items: [String]
    let color: Color

    var body: some View {
        FlexibleView(
            data: items,
            spacing: 8,
            alignment: .leading
        ) { item in
            Text(item)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(color.opacity(0.2))
                .foregroundStyle(color)
                .clipShape(Capsule())
        }
    }
}

// MARK: - FlexibleView (FlowLayout alternative)
struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    @State private var availableWidth: CGFloat = 0

    var body: some View {
        ZStack(alignment: Alignment(horizontal: alignment, vertical: .center)) {
            Color.clear
                .frame(height: 1)
                .readSize { size in
                    availableWidth = size.width
                }

            FlexibleViewContent(
                availableWidth: availableWidth,
                data: data,
                spacing: spacing,
                alignment: alignment,
                content: content
            )
        }
    }
}

private struct FlexibleViewContent<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let availableWidth: CGFloat
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            ForEach(computeRows(), id: \.self) { rowElements in
                HStack(spacing: spacing) {
                    ForEach(rowElements, id: \.self) { element in
                        content(element)
                    }
                }
            }
        }
    }

    private func computeRows() -> [[Data.Element]] {
        var rows: [[Data.Element]] = [[]]
        var currentRow = 0
        var remainingWidth = availableWidth

        for element in data {
            let elementWidth = CGFloat(element.hashValue % 100 + 80) // Approximation

            if remainingWidth - elementWidth >= 0 {
                rows[currentRow].append(element)
            } else {
                currentRow += 1
                rows.append([element])
                remainingWidth = availableWidth
            }

            remainingWidth -= (elementWidth + spacing)
        }

        return rows
    }
}

// MARK: - Size Reader
private extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

// MARK: - Add to Collection Sheet
struct MacAddToCollectionView: View {
    let manga: Manga

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    @State private var volumesOwnedCount: Double = 1
    @State private var currentReadingVolume: Double = 1
    @State private var isSaving = false

    private var totalVolumes: Int {
        manga.volumes ?? 50
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack(spacing: 16) {
                CachedCoverImage(
                    url: manga.coverURL,
                    width: 80,
                    height: 120
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(manga.title)
                        .font(.title2.bold())
                        .lineLimit(2)

                    if let total = manga.volumes {
                        Text("\(total) volumes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text("status_publishing")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                    }

                    if manga.score > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text(manga.score.formatted(.number.precision(.fractionLength(1))))
                        }
                        .font(.subheadline)
                    }
                }

                Spacer()
            }
            .padding(.horizontal)

            Divider()

            // Info
            if manga.volumes == nil {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.orange)
                    Text("edit_ongoing_manga")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }

            // Sliders
            VStack(spacing: 32) {
                // Volumenes en propiedad
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("edit_volumes_owned", systemImage: "books.vertical.fill")
                            .font(.headline)
                        Spacer()

                        HStack(spacing: 4) {
                            TextField("", value: $volumesOwnedCount, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                                .multilineTextAlignment(.center)

                            if let total = manga.volumes {
                                Text("/ \(total)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.title3.bold().monospacedDigit())
                    }

                    Slider(value: $volumesOwnedCount, in: 0...Double(totalVolumes), step: 1)
                        .tint(.blue)
                }

                // Volumen de lectura actual
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("edit_reading_volume", systemImage: "bookmark.fill")
                            .font(.headline)
                        Spacer()

                        TextField("", value: $currentReadingVolume, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .multilineTextAlignment(.center)
                            .font(.title3.bold().monospacedDigit())
                    }

                    Slider(value: $currentReadingVolume, in: 1...max(1, Double(totalVolumes), volumesOwnedCount), step: 1)
                        .tint(.orange)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Botones
            HStack(spacing: 16) {
                Button("action_cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.bordered)

                Button("action_add") {
                    Task {
                        await saveToCollection()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
            }
            .padding()
        }
        .padding(.vertical)
        .frame(width: 450, height: 420)
    }

    private func saveToCollection() async {
        isSaving = true

        let ownedCount = Int(volumesOwnedCount)
        let volumes = ownedCount > 0 ? Array(1...ownedCount) : []
        let readingVol = Int(currentReadingVolume)
        let isComplete = ownedCount == totalVolumes

        // Guardar en local usando DataContainer (background)
        let dataContainer = DataContainer(modelContainer: modelContext.container)
        do {
            try await dataContainer.addToCollection(
                manga: manga,
                volumesOwned: volumes,
                currentReadingVolume: readingVol,
                hasCompleteCollection: isComplete
            )
        } catch {
            print("Error al guardar en local: \(error)")
            isSaving = false
            return
        }

        // Si está logueado, TAMBIÉN guardar en cloud
        if authVM.isAuthenticated {
            do {
                try await cloudVM.addToCollection(
                    manga: manga,
                    volumesOwned: volumes,
                    readingVolume: readingVol,
                    completeCollection: isComplete
                )
            } catch {
                print("Error al guardar en cloud: \(error)")
            }
        }

        isSaving = false
        dismiss()
    }
}

#Preview {
    MacMangaDetailView(manga: .test)
        .environment(CloudCollectionViewModel(authVM: AuthViewModel()))
        .environment(AuthViewModel())
        .modelContainer(.preview)
}
