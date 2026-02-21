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

    @State private var showAddToCollection = false
    @State private var characters: [JikanCharacterData] = []
    @State private var isLoadingCharacters = false

    // Related mangas states
    @State private var relatedMangas: [JikanRelation] = []
    @State private var relatedMangaDetails: [Int: Manga] = [:]
    @State private var recommendations: [JikanRecommendation] = []
    @State private var isLoadingRelated = false

    // Navigation state for related mangas
    @State private var selectedRelatedManga: Manga?
    @State private var isLoadingManga = false

    // Translation states
    @State private var translatedSynopsis: String?
    @State private var translatedBackground: String?
    @State private var isTranslating = false
    @State private var showOriginal = false

    private let repository = Network()
    private let translationService = TranslationService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header con imagen y datos principales
                HStack(alignment: .top, spacing: 24) {
                    // Portada
                    CachedCoverImage(
                        url: URL(string: manga.mainPicture.replacingOccurrences(of: "\"", with: "")),
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
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                    Text(String(format: "%.2f", manga.score))
                                        .font(.title2.bold())
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
                        Button {
                            showAddToCollection = true
                        } label: {
                            Label(
                                authVM.isAuthenticated && cloudVM.isInCollection(manga.id) ? String(localized: "detail_in_collection") : String(localized: "detail_add_to_collection"),
                                systemImage: "plus.circle.fill"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
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

                    if isLoadingCharacters {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical)
                    } else if characters.isEmpty {
                        Text("detail_characters_empty")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 16) {
                                ForEach(characters) { characterData in
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

                    if isLoadingRelated {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical)
                    } else if relatedMangas.isEmpty && recommendations.isEmpty {
                        Text("detail_related_empty")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        // Relaciones directas
                        ForEach(relatedMangas) { relation in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(localizedRelationType(relation.relation))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                ScrollView(.horizontal) {
                                    HStack(spacing: 16) {
                                        ForEach(relation.entry.filter { $0.type == "manga" }) { entry in
                                            Button {
                                                Task {
                                                    await loadAndNavigateToManga(id: entry.malId)
                                                }
                                            } label: {
                                                VStack(spacing: 6) {
                                                    if let mangaDetail = relatedMangaDetails[entry.malId] {
                                                        CachedCoverImage(
                                                            url: URL(string: mangaDetail.mainPicture.replacingOccurrences(of: "\"", with: "")),
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
                        if !recommendations.isEmpty {
                            Text("detail_recommendations")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 12)

                            ScrollView(.horizontal) {
                                HStack(spacing: 16) {
                                    ForEach(recommendations.prefix(10)) { rec in
                                        Button {
                                            Task {
                                                await loadAndNavigateToManga(id: rec.entry.malId)
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

                            if translationService.isConfigured && translationService.needsTranslation {
                                if isTranslating {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else if translatedSynopsis != nil {
                                    Button {
                                        showOriginal.toggle()
                                    } label: {
                                        Label(
                                            showOriginal ? "translation_show_translated" : "translation_show_original",
                                            systemImage: "globe"
                                        )
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                        }

                        Text(showOriginal ? synopsis : (translatedSynopsis ?? synopsis))
                            .lineSpacing(6)
                    }
                }

                // Background
                if let background = manga.background {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("detail_background")
                            .font(.title2.bold())

                        Text(showOriginal ? background : (translatedBackground ?? background))
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
        .sheet(item: $selectedRelatedManga) { relatedManga in
            NavigationStack {
                MacMangaDetailView(manga: relatedManga)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("action_close") {
                                selectedRelatedManga = nil
                            }
                        }
                    }
            }
            .frame(minWidth: 800, minHeight: 600)
        }
        .task(id: manga.id) {
            characters = []
            relatedMangas = []
            relatedMangaDetails = [:]
            recommendations = []
            translatedSynopsis = nil
            translatedBackground = nil
            showOriginal = false
            await loadCharacters()
            await loadRelatedMangas()
            await translateContent()
        }
    }

    private func loadRelatedMangas() async {
        isLoadingRelated = true
        do {
            async let relations = repository.getMangaRelations(mangaId: manga.id)
            async let recs = repository.getMangaRecommendations(mangaId: manga.id)

            relatedMangas = try await relations
            recommendations = try await recs

            // Fetch detalles de mangas relacionados en paralelo
            await fetchRelatedMangaDetails()
        } catch {
            print("Error cargando mangas relacionados: \(error)")
            relatedMangas = []
            recommendations = []
        }
        isLoadingRelated = false
    }

    private func fetchRelatedMangaDetails() async {
        let mangaIds = relatedMangas
            .flatMap { $0.entry }
            .filter { $0.type == "manga" }
            .map { $0.malId }

        await withTaskGroup(of: (Int, Manga?).self) { group in
            for id in mangaIds {
                group.addTask {
                    do {
                        let manga = try await self.repository.getManga(byId: id)
                        return (id, manga)
                    } catch {
                        return (id, nil)
                    }
                }
            }

            for await (id, manga) in group {
                if let manga = manga {
                    relatedMangaDetails[id] = manga
                }
            }
        }
    }

    private func loadAndNavigateToManga(id: Int) async {
        isLoadingManga = true
        do {
            let manga = try await repository.getManga(byId: id)
            selectedRelatedManga = manga
        } catch {
            print("Error cargando manga relacionado: \(error)")
        }
        isLoadingManga = false
    }

    private func localizedRelationType(_ type: String) -> String {
        switch type.lowercased() {
        case "sequel": return String(localized: "relation_sequel")
        case "prequel": return String(localized: "relation_prequel")
        case "side story": return String(localized: "relation_side_story")
        case "spin-off": return String(localized: "relation_spin_off")
        case "alternative version": return String(localized: "relation_alternative")
        case "alternative setting": return String(localized: "relation_alternative_setting")
        case "adaptation": return String(localized: "relation_adaptation")
        case "summary": return String(localized: "relation_summary")
        case "full story": return String(localized: "relation_full_story")
        case "parent story": return String(localized: "relation_parent_story")
        case "other": return String(localized: "relation_other")
        default: return type
        }
    }

    private func translateContent() async {
        guard translationService.isConfigured && translationService.needsTranslation else { return }

        isTranslating = true
        let targetLanguage = translationService.currentLanguageCode

        do {
            if let synopsis = manga.sypnosis {
                translatedSynopsis = try await translationService.translate(synopsis, to: targetLanguage)
            }
            if let background = manga.background {
                translatedBackground = try await translationService.translate(background, to: targetLanguage)
            }
        } catch {
            print("Error traduciendo contenido: \(error)")
        }

        isTranslating = false
    }

    private func loadCharacters() async {
        isLoadingCharacters = true
        do {
            characters = try await repository.getMangaCharacters(mangaId: manga.id)
        } catch {
            print("Error cargando personajes: \(error)")
            characters = []
        }
        isLoadingCharacters = false
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

    @State private var selectedVolumes: Set<Int> = []
    @State private var currentReadingVolume: Int = 1
    @State private var hasCompleteCollection = false
    @State private var isSaving = false

    var body: some View {
        VStack(spacing: 20) {
            Text("nav_add_collection")
                .font(.title.bold())

            CachedCoverImage(
                url: URL(string: manga.mainPicture.replacingOccurrences(of: "\"", with: "")),
                width: 150,
                height: 225
            )

            Text(manga.title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Form {
                Toggle("add_complete_collection", isOn: $hasCompleteCollection)
                    .onChange(of: hasCompleteCollection) { _, newValue in
                        if newValue, let totalVolumes = manga.volumes {
                            selectedVolumes = Set(1...totalVolumes)
                        }
                    }

                if !hasCompleteCollection {
                    HStack {
                        Text("detail_volumes")
                        TextField("1,2,3", text: Binding(
                            get: {
                                selectedVolumes.sorted().map(String.init).joined(separator: ",")
                            },
                            set: { text in
                                let volumes = text.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                                selectedVolumes = Set(volumes)
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
            }
            .padding()

            Spacer()

            HStack {
                Button("action_cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("action_add") {
                    Task {
                        await saveToCollection()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(selectedVolumes.isEmpty && !hasCompleteCollection || isSaving)
            }
            .padding()
        }
        .padding()
        .frame(width: 500, height: 600)
    }

    private func saveToCollection() async {
        isSaving = true
        let volumes = Array(selectedVolumes).sorted()

        // Guardar en local usando DataContainer (background)
        let dataContainer = DataContainer(modelContainer: modelContext.container)
        do {
            try await dataContainer.addToCollection(
                manga: manga,
                volumesOwned: volumes,
                currentReadingVolume: currentReadingVolume,
                hasCompleteCollection: hasCompleteCollection
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
                    readingVolume: currentReadingVolume,
                    completeCollection: hasCompleteCollection
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
