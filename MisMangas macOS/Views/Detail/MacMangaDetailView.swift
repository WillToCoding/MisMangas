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

    @Environment(CloudCollectionViewModel.self) var cloudVM
    @Environment(AuthViewModel.self) var authVM
    @Environment(TranslationService.self) private var translationService

    @State var viewModel: MangaDetailViewModel
    @State var showAddToCollection = false
    @State var showEditCollection = false

    init(manga: Manga) {
        self.manga = manga
        _viewModel = State(initialValue: MangaDetailViewModel(manga: manga))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                Divider()
                authorsSection
                categoriesSection
                charactersSection
                relatedMangasSection
                synopsisSection
                backgroundSection
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
        FlexibleView(data: items, spacing: 8, alignment: .leading) { item in
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

// MARK: - FlexibleView (FlowLayout)

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
                .readSize { availableWidth = $0.width }

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
            let elementWidth = CGFloat(element.hashValue % 100 + 80)

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

// MARK: - Preview

#Preview {
    MacMangaDetailView(manga: .test)
        .environment(CloudCollectionViewModel(authVM: AuthViewModel()))
        .environment(AuthViewModel())
        .environment(TranslationService())
        .modelContainer(.preview)
}
