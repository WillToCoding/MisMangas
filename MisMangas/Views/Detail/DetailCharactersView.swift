//
//  DetailCharactersView.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI

struct DetailCharactersView: View {
    let characters: [JikanCharacterData]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("detail_characters")
                .font(.headline)
                .accessibilityHeader(.h2)

            content
        }
    }

    private var content: some View {
        Group {
            if isLoading {
                loadingView
            } else if characters.isEmpty {
                emptyView
            } else {
                charactersList
            }
        }
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .accessibilityLabel(String(localized: "accessibility_loading_characters"))
            Spacer()
        }
        .padding(.vertical)
    }

    private var emptyView: some View {
        Text("detail_characters_empty")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var charactersList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(characters) { characterData in
                    CharacterCard(characterData: characterData)
                }
            }
        }
    }
}

// MARK: - Character Card
private struct CharacterCard: View {
    let characterData: JikanCharacterData

    var body: some View {
        VStack(spacing: 6) {
            CachedCoverImage(
                url: URL(string: characterData.character.images.jpg.imageUrl),
                width: 80,
                height: 100
            )
            .accessibilityHidden(true)

            Text(characterData.character.name)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 80)

            Text(characterData.role)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(characterData.character.name), \(characterData.role)")
    }
}

#Preview {
    DetailCharactersView(characters: [], isLoading: false)
        .padding()
}

#Preview("Loading") {
    DetailCharactersView(characters: [], isLoading: true)
        .padding()
}
