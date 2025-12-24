//
//  MangaDetailView.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI
import SwiftData

struct MangaDetailView: View {
    let manga: Manga
    @State private var showAddToCollection = false
    @State private var characters: [JikanCharacterData] = []
    @State private var isLoadingCharacters = false

    // Related mangas states
    @State private var relatedMangas: [JikanRelation] = []
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

    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Query private var localCollection: [Model]

    private let repository = NetworkRepository()
    private let translationService = TranslationService.shared

    private var isInLocalCollection: Bool {
        localCollection.contains { $0.id == manga.id }
    }

    private var isInCloudCollection: Bool {
        cloudVM.isInCollection(manga.id)
    }

    private var collectionStatus: String {
        if authVM.isAuthenticated {
            return isInCloudCollection ? String(localized: "detail_in_cloud") : String(localized: "detail_add_to_cloud")
        } else {
            return isInLocalCollection ? String(localized: "detail_in_collection") : String(localized: "detail_add_to_collection")
        }
    }

    private var collectionIcon: String {
        if authVM.isAuthenticated {
            return isInCloudCollection ? "checkmark.cloud.fill" : "cloud.fill"
        } else {
            return isInLocalCollection ? "checkmark.circle.fill" : "plus.circle.fill"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Portada grande
                AsyncImage(url: URL(string: manga.mainPicture.replacingOccurrences(of: "\"", with: ""))) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 400)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 8)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 16) {
                    // Título
                    Text(manga.title)
                        .font(.title.bold())

                    if let englishTitle = manga.titleEnglish, englishTitle != manga.title {
                        Text(englishTitle)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    if let japaneseTitle = manga.titleJapanese {
                        Text(japaneseTitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Stats
                    HStack(spacing: 20) {
                        Label("\(manga.score, specifier: "%.2f")", systemImage: "star.fill")
                            .foregroundStyle(.orange)
                            .font(.headline)

                        if let volumes = manga.volumes {
                            Label(String(format: String(localized: "detail_vols_format"), volumes), systemImage: "books.vertical")
                        }

                        if let chapters = manga.chapters {
                            Label(String(format: String(localized: "detail_caps_format"), chapters), systemImage: "book.pages")
                        }

                        Label(manga.status == "finished" ? String(localized: "status_finished") : String(localized: "status_publishing"), systemImage: manga.status == "finished" ? "checkmark.circle.fill" : "clock.fill")
                            .foregroundStyle(manga.status == "finished" ? .green : .blue)
                    }
                    .font(.subheadline)

                    Divider()

                    // Autores
                    if !manga.authors.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("detail_authors")
                                .font(.headline)

                            ForEach(manga.authors) { author in
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundStyle(.blue)

                                    VStack(alignment: .leading) {
                                        Text("\(author.firstName) \(author.lastName)")
                                            .font(.subheadline)
                                        Text(author.role)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }

                        Divider()
                    }

                    // Géneros
                    if !manga.genres.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("detail_genres")
                                .font(.headline)

                            FlowLayout(spacing: 8) {
                                ForEach(manga.genres) { genre in
                                    Text(localizedAPIValue(genre.genre))
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(.blue.opacity(0.2))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        Divider()
                    }

                    // Temas
                    if !manga.themes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("detail_themes")
                                .font(.headline)

                            FlowLayout(spacing: 8) {
                                ForEach(manga.themes) { theme in
                                    Text(localizedAPIValue(theme.theme))
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(.purple.opacity(0.2))
                                        .foregroundStyle(.purple)
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        Divider()
                    }

                    // Demografía
                    if !manga.demographics.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("detail_demographics")
                                .font(.headline)

                            ForEach(manga.demographics) { demo in
                                Text(localizedAPIValue(demo.demographic))
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.green.opacity(0.2))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
                            }
                        }

                        Divider()
                    }

                    // Personajes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("detail_characters")
                            .font(.headline)

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
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(characters) { characterData in
                                        VStack(spacing: 6) {
                                            AsyncImage(url: URL(string: characterData.character.images.jpg.imageUrl)) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                Color.gray.opacity(0.3)
                                            }
                                            .frame(width: 80, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))

                                            Text(characterData.character.name)
                                                .font(.caption2)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.center)
                                                .frame(width: 80)

                                            Text(characterData.role)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    // Mangas Relacionados
                    VStack(alignment: .leading, spacing: 8) {
                        Text("detail_related_mangas")
                            .font(.headline)

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
                            // Relaciones directas (secuelas, precuelas, etc.)
                            ForEach(relatedMangas) { relation in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(localizedRelationType(relation.relation))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(relation.entry.filter { $0.type == "manga" }) { entry in
                                                Button {
                                                    Task {
                                                        await loadAndNavigateToManga(id: entry.malId)
                                                    }
                                                } label: {
                                                    VStack(spacing: 4) {
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(Color.blue.opacity(0.2))
                                                            .frame(width: 60, height: 80)
                                                            .overlay {
                                                                if isLoadingManga {
                                                                    ProgressView()
                                                                } else {
                                                                    Image(systemName: "book.fill")
                                                                        .foregroundStyle(.blue)
                                                                }
                                                            }

                                                        Text(entry.name)
                                                            .font(.caption2)
                                                            .lineLimit(2)
                                                            .multilineTextAlignment(.center)
                                                            .frame(width: 60)
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
                                    .padding(.top, 8)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(recommendations.prefix(10)) { rec in
                                            Button {
                                                Task {
                                                    await loadAndNavigateToManga(id: rec.entry.malId)
                                                }
                                            } label: {
                                                VStack(spacing: 4) {
                                                    AsyncImage(url: URL(string: rec.entry.images.jpg.imageUrl)) { image in
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                    } placeholder: {
                                                        Color.gray.opacity(0.3)
                                                    }
                                                    .frame(width: 60, height: 80)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                                    Text(rec.entry.title)
                                                        .font(.caption2)
                                                        .lineLimit(2)
                                                        .multilineTextAlignment(.center)
                                                        .frame(width: 60)
                                                        .foregroundStyle(.primary)

                                                    HStack(spacing: 2) {
                                                        Image(systemName: "hand.thumbsup.fill")
                                                            .font(.system(size: 8))
                                                        Text("\(rec.votes)")
                                                            .font(.system(size: 8))
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

                    Divider()

                    // Sinopsis
                    if let synopsis = manga.sypnosis {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("detail_synopsis")
                                    .font(.headline)

                                Spacer()

                                if translationService.isConfigured && translationService.needsTranslation {
                                    if isTranslating {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else if translatedSynopsis != nil {
                                        Button {
                                            showOriginal.toggle()
                                        } label: {
                                            Label(
                                                showOriginal ? "translation_show_translated" : "translation_show_original",
                                                systemImage: "globe"
                                            )
                                            .font(.caption)
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                }
                            }

                            Text(showOriginal ? synopsis : (translatedSynopsis ?? synopsis))
                                .font(.body)
                                .lineSpacing(4)
                        }

                        Divider()
                    }

                    // Background
                    if let background = manga.background {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("detail_background")
                                .font(.headline)

                            Text(showOriginal ? background : (translatedBackground ?? background))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineSpacing(4)
                        }
                    }

                    // Fechas
                    if let startDate = manga.startDate {
                        HStack {
                            Text("detail_start_date")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(formatDate(startDate))
                                .font(.caption)
                        }
                    }

                    if let endDate = manga.endDate {
                        HStack {
                            Text("detail_end_date")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(formatDate(endDate))
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("nav_detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(collectionStatus, systemImage: collectionIcon) {
                    showAddToCollection = true
                }
                .foregroundStyle(isInCloudCollection || isInLocalCollection ? .green : .blue)
            }
        }
        .sheet(isPresented: $showAddToCollection) {
            AddToCollectionView(manga: manga)
        }
        .navigationDestination(item: $selectedRelatedManga) { manga in
            MangaDetailView(manga: manga)
        }
        .task(id: manga.id) {
            characters = []
            relatedMangas = []
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
        } catch {
            print("Error cargando mangas relacionados: \(error)")
            relatedMangas = []
            recommendations = []
        }
        isLoadingRelated = false
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
        // Solo traducir si el servicio está configurado y el idioma no es inglés
        guard translationService.isConfigured && translationService.needsTranslation else { return }

        isTranslating = true
        let targetLanguage = translationService.currentLanguageCode

        do {
            // Traducir sinopsis
            if let synopsis = manga.sypnosis {
                translatedSynopsis = try await translationService.translate(synopsis, to: targetLanguage)
            }

            // Traducir background
            if let background = manga.background {
                translatedBackground = try await translationService.translate(background, to: targetLanguage)
            }
        } catch {
            print("Error traduciendo contenido: \(error)")
            // En caso de error, mantener el texto original
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

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// FlowLayout para los tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    NavigationStack {
        MangaDetailView(manga: .test)
    }
}
