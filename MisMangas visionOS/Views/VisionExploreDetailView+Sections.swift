//
//  VisionExploreDetailView+Sections.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 26/02/26.
//

import SwiftUI

// MARK: - Cover Section

extension VisionExploreDetailView {
    var coverSection: some View {
        Group {
            if let image = coverVM.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .overlay {
                        if coverVM.isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.gray)
                        }
                    }
            }
        }
        .frame(width: 350, height: 525)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 30)
        .onAppear {
            coverVM.getImage(url: manga.coverURL)
        }
    }
}

// MARK: - Info Section

extension VisionExploreDetailView {
    var infoSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            titleSection
            statsSection
            genresSection

            Divider()

            if let synopsis = manga.sypnosis, !synopsis.isEmpty {
                synopsisSection(synopsis: synopsis)
            }

            Spacer()

            collectionButton
        }
        .frame(maxWidth: 600, alignment: .leading)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(manga.title)
                .font(.system(size: 42, weight: .bold))

            if let titleJapanese = manga.titleJapanese {
                Text(titleJapanese)
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 30) {
            Label(manga.score.formatted(.number.precision(.fractionLength(2))), systemImage: "star.fill")
                .foregroundStyle(.yellow)
                .font(.title3.bold())

            if let volumes = manga.volumes {
                Label("\(volumes) vol.", systemImage: "book.closed")
                    .foregroundStyle(.blue)
                    .font(.title3)
            }

            if let chapters = manga.chapters {
                Label("\(chapters) cap.", systemImage: "doc.text")
                    .foregroundStyle(.green)
                    .font(.title3)
            }

            Label(manga.status.capitalized, systemImage: manga.status == "finished" ? "checkmark.circle.fill" : "clock")
                .foregroundStyle(manga.status == "finished" ? .green : .orange)
                .font(.title3)
        }
    }

    private var genresSection: some View {
        Group {
            if !manga.genres.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("detail_genres")
                        .font(.title3.bold())

                    HStack(spacing: 10) {
                        ForEach(manga.genres.prefix(5)) { genre in
                            Text(genre.genre)
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.blue.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    func synopsisSection(synopsis: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("detail_synopsis")
                    .font(.title2.bold())
                Spacer()
                translationButton(synopsis: synopsis)
            }

            Text(showOriginal ? synopsis : (translatedSynopsis ?? synopsis))
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(showFullSynopsis ? nil : 6)

            Button {
                withAnimation {
                    showFullSynopsis.toggle()
                }
            } label: {
                Text(showFullSynopsis ? "home_show_less" : "home_show_more")
                    .font(.subheadline.bold())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
        }
    }

    @ViewBuilder
    var collectionButton: some View {
        if isInCollection {
            Label("collection_already_added", systemImage: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)
        } else {
            Button {
                showAddSheet = true
            } label: {
                Label("action_add_collection", systemImage: "plus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

// MARK: - Translation

extension VisionExploreDetailView {
    func translationButton(synopsis: String) -> some View {
        Group {
            if translationService.isConfigured {
                if isTranslating {
                    ProgressView()
                } else if translatedSynopsis != nil {
                    Button {
                        showOriginal.toggle()
                    } label: {
                        Label(
                            showOriginal ? "translation_show_translated" : "translation_show_original",
                            systemImage: "globe"
                        )
                        .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        Task { await translateSynopsis(synopsis) }
                    } label: {
                        Label("translation_translate", systemImage: "globe")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    func translateSynopsis(_ synopsis: String) async {
        isTranslating = true
        let targetLanguage = Locale.current.language.languageCode?.identifier ?? "es"

        do {
            translatedSynopsis = try await translationService.translate(synopsis, to: targetLanguage)
        } catch {
            print("[VISION] Error traduciendo: \(error)")
        }

        isTranslating = false
    }
}

// MARK: - Helpers

extension VisionExploreDetailView {
    func checkIfInCollection() {
        if authVM.isAuthenticated {
            isInCollection = cloudVM.cloudCollection.contains { $0.manga.id == manga.id }
        } else {
            isInCollection = localCollection.contains { $0.manga.id == manga.id }
        }
    }
}
