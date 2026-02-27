//
//  VisionMangaDetailView.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct VisionMangaDetailView<Item: CollectionItem>: View {
    let item: Item
    let onSave: (Int, [Int], Bool) async throws -> Void
    let onDelete: () async throws -> Void

    @Environment(TranslationService.self) var translationService
    @Environment(\.dismiss) var dismiss

    @State var coverVM = MangaCoverVM()
    @State var currentVolume: Int
    @State var ownedVolumes: Int
    @State var isCompleted: Bool
    @State var isSaving = false
    @State var showSuccess = false
    @State var showDeleteAlert = false
    @State var isDeleting = false

    // Synopsis
    @State var showFullSynopsis = false
    @State var translatedSynopsis: String?
    @State var isTranslating = false
    @State var showOriginal = false

    init(
        item: Item,
        onSave: @escaping (Int, [Int], Bool) async throws -> Void,
        onDelete: @escaping () async throws -> Void
    ) {
        self.item = item
        self.onSave = onSave
        self.onDelete = onDelete
        _currentVolume = State(initialValue: item.collectionReadingVolume ?? 1)
        _ownedVolumes = State(initialValue: item.collectionVolumesOwned.count)
        _isCompleted = State(initialValue: item.collectionIsComplete)
    }

    var totalVolumes: Int {
        item.collectionTotalVolumes ?? 50
    }

    var hasChanges: Bool {
        currentVolume != item.collectionReadingVolume ||
        ownedVolumes != item.collectionVolumesOwned.count ||
        isCompleted != item.collectionIsComplete
    }

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 60) {
                coverSection
                infoSection
            }
            .padding(60)
        }
        .navigationTitle(item.collectionTitle)
        .alert("collection_delete_title", isPresented: $showDeleteAlert) {
            Button("action_cancel", role: .cancel) { }
            Button("action_delete", role: .destructive) {
                Task { await deleteManga() }
            }
        } message: {
            Text("collection_delete_message")
        }
        .task {
            coverVM.getImage(url: item.collectionCoverURL)
        }
    }
}

#Preview {
    NavigationStack {
        VisionMangaDetailView(
            item: UserMangaCollection.test,
            onSave: { _, _, _ in },
            onDelete: { }
        )
    }
    .environment(TranslationService())
}
