//
//  MacMangaDetailView+Sections.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

// MARK: - Header Section

extension MacMangaDetailView {
    var headerSection: some View {
        HStack(alignment: .top, spacing: 24) {
            CachedCoverImage(
                url: manga.coverURL,
                width: 250,
                height: 375
            )
            .shadow(radius: 8)

            VStack(alignment: .leading, spacing: 16) {
                titleSection
                Divider()
                statsRow
                Divider()
                actionButton
            }
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
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
        }
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            statItem(title: "detail_score", value: manga.score.formatted(.number.precision(.fractionLength(2))), icon: "star.fill", iconColor: .yellow)

            if let volumes = manga.volumes {
                statItem(title: "detail_volumes", value: "\(volumes)")
            }

            if let chapters = manga.chapters {
                statItem(title: "detail_chapters", value: "\(chapters)")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("detail_status")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(manga.status == "finished" ? String(localized: "status_finished") : String(localized: "status_publishing"))
                    .font(.subheadline.bold())
                    .foregroundStyle(manga.status == "finished" ? .green : .blue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    private func statItem(title: LocalizedStringKey, value: String, icon: String? = nil, iconColor: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                }
                Text(value)
                    .font(.headline)
            }
        }
        .frame(minWidth: 50)
    }

    private var actionButton: some View {
        Group {
            if authVM.isAuthenticated && cloudVM.isInCollection(manga.id) {
                Button {
                    showEditCollection = true
                } label: {
                    Label("detail_edit_collection", systemImage: "pencil.circle.fill")
                }
            } else {
                Button {
                    showAddToCollection = true
                } label: {
                    Label("detail_add_to_collection", systemImage: "plus.circle.fill")
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}

// MARK: - Authors Section

extension MacMangaDetailView {
    var authorsSection: some View {
        Group {
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
        }
    }
}

// MARK: - Categories Section

extension MacMangaDetailView {
    var categoriesSection: some View {
        Group {
            if !manga.genres.isEmpty || !manga.themes.isEmpty || !manga.demographics.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("mac_categories")
                        .font(.title2.bold())

                    if !manga.genres.isEmpty {
                        categoryRow(title: "detail_genres", items: manga.genres.map { localizedAPIValue($0.genre) }, color: .blue)
                    }

                    if !manga.themes.isEmpty {
                        categoryRow(title: "detail_themes", items: manga.themes.map { localizedAPIValue($0.theme) }, color: .purple)
                    }

                    if !manga.demographics.isEmpty {
                        categoryRow(title: "detail_demographics", items: manga.demographics.map { localizedAPIValue($0.demographic) }, color: .green)
                    }
                }
            }
        }
    }

    private func categoryRow(title: LocalizedStringKey, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            WrappingHStack(items: items, color: color)
        }
    }
}

// MARK: - Characters Section

extension MacMangaDetailView {
    var charactersSection: some View {
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
                            characterCard(characterData)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: 180)
            }
        }
    }

    private func characterCard(_ characterData: JikanCharacterData) -> some View {
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

// MARK: - Synopsis Section

extension MacMangaDetailView {
    var synopsisSection: some View {
        Group {
            if let synopsis = manga.sypnosis {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("detail_synopsis")
                            .font(.title2.bold())

                        Spacer()

                        translationButton
                    }

                    Text(viewModel.showOriginal ? synopsis : (viewModel.translatedSynopsis ?? synopsis))
                        .lineSpacing(6)
                }
            }
        }
    }

    private var translationButton: some View {
        Group {
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
    }

    var backgroundSection: some View {
        Group {
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
    }
}
