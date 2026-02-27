//
//  TVMangaDetailView.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct TVMangaDetailView<Item: CollectionItem>: View {
    let item: Item
    let onSave: (Int, [Int], Bool) async throws -> Void
    let onDelete: () async throws -> Void
    let onRefresh: () async -> Void

    @Environment(TranslationService.self) var translationService
    @Environment(\.dismiss) var dismiss

    @State var coverVM = MangaCoverVM()
    @State var currentVolume: Double
    @State var ownedVolumes: Double
    @State var isCompleted: Bool
    @State var isSaving = false
    @State var showSavedConfirmation = false
    @State var showDeleteAlert = false
    @State var isDeleting = false

    // Traducción
    @State var translatedSynopsis: String?
    @State var isTranslating = false
    @State var showOriginal = false
    @State var showFullSynopsis = false

    init(
        item: Item,
        onSave: @escaping (Int, [Int], Bool) async throws -> Void,
        onDelete: @escaping () async throws -> Void,
        onRefresh: @escaping () async -> Void = {}
    ) {
        self.item = item
        self.onSave = onSave
        self.onDelete = onDelete
        self.onRefresh = onRefresh
        _currentVolume = State(initialValue: Double(item.collectionReadingVolume ?? 1))
        _ownedVolumes = State(initialValue: Double(item.collectionVolumesOwned.count))
        _isCompleted = State(initialValue: item.collectionIsComplete)
    }

    // MARK: - Computed Properties

    var totalVolumes: Int {
        item.collectionTotalVolumes ?? 50
    }

    var progressPercentage: Int {
        Int((currentVolume / Double(totalVolumes)) * 100)
    }

    var hasChanges: Bool {
        Int(currentVolume) != item.collectionReadingVolume ||
        Int(ownedVolumes) != item.collectionVolumesOwned.count ||
        isCompleted != item.collectionIsComplete
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 50) {
                // Back Button
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Label("action_back", systemImage: "chevron.left")
                            .font(.system(size: 32, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                }
                .focusSection()

                // Cover + Info
                HStack(alignment: .top, spacing: 80) {
                    coverSection
                    infoSection
                }

                // Synopsis
                synopsisSection
                    .focusSection()

                Divider()
                    .background(.secondary)

                // Controls
                volumesOwnedSection
                    .focusSection()

                readingVolumeSection
                    .focusSection()

                readingStatusSection
                    .focusSection()

                // Buttons
                saveButtonSection
                    .focusSection()

                deleteButtonSection
                    .focusSection()

                Spacer(minLength: 100)
            }
            .padding(80)
        }
        .navigationTitle(item.collectionTitle)
        .task {
            guard let url = item.collectionCoverURL else { return }
            coverVM.getImage(url: url)
        }
        .onExitCommand {
            dismiss()
        }
        .alert("collection_delete_title", isPresented: $showDeleteAlert) {
            Button("action_cancel", role: .cancel) { }
            Button("action_delete", role: .destructive) {
                Task {
                    await deleteManga()
                }
            }
        } message: {
            Text("collection_delete_message")
        }
    }
}

#Preview {
    let authVM = AuthViewModel()
    return NavigationStack {
        TVMangaDetailView(
            item: UserMangaCollection.test,
            onSave: { _, _, _ in },
            onDelete: { },
            onRefresh: { }
        )
    }
    .environment(authVM)
    .environment(TranslationService())
}
