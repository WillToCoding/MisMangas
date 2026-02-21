//
//  MacCollectionView.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI
import SwiftData

struct MacCollectionView: View {
    @Binding var selection: Manga?

    @Query(sort: \UserCollection.addedDate, order: .reverse) private var localCollection: [UserCollection]
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    @State private var showDeleteAlert = false
    @State private var mangaToDelete: Int?
    @State private var showEditSheet = false
    @State private var collectionItemToEdit: UserMangaCollection?
    @State private var localItemToEdit: UserCollection?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(authVM.isAuthenticated ? "collection_cloud_label" : "collection_local")
                    .font(.headline)

                Spacer()

                if authVM.isAuthenticated {
                    Image(systemName: "cloud.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding()

            Divider()

            // Lista
            if authVM.isAuthenticated {
                cloudCollectionView
            } else {
                localCollectionView
            }
        }
        .navigationTitle("nav_collection")
        .task {
            if authVM.isAuthenticated {
                await cloudVM.loadCollection()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshContent)) { _ in
            if authVM.isAuthenticated {
                Task {
                    await cloudVM.loadCollection()
                }
            }
        }
        .alert("collection_delete_title", isPresented: $showDeleteAlert) {
            Button("action_cancel", role: .cancel) { }
            Button("action_delete", role: .destructive) {
                if let mangaId = mangaToDelete {
                    Task {
                        try? await cloudVM.removeFromCollection(mangaId: mangaId)
                    }
                }
            }
        } message: {
            Text("collection_delete_message")
        }
        .sheet(item: $collectionItemToEdit) { item in
            MacEditCollectionView(collectionItem: item)
        }
        .sheet(item: $localItemToEdit) { item in
            MacEditLocalCollectionView(collection: item)
        }
    }

    // MARK: - Cloud Collection View

    @ViewBuilder
    private var cloudCollectionView: some View {
        if cloudVM.isLoading {
            ProgressView("loading_collection")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if cloudVM.cloudCollection.isEmpty {
            emptyStateView
        } else {
            List(cloudVM.cloudCollection, id: \.id, selection: $selection) { item in
                MacMangaRow(manga: item.manga)
                    .tag(item.manga)
                    .contextMenu {
                        Button {
                            collectionItemToEdit = item
                        } label: {
                            Label("action_edit", systemImage: "pencil")
                        }

                        Divider()

                        Button("action_delete", role: .destructive) {
                            mangaToDelete = item.manga.id
                            showDeleteAlert = true
                        }
                    }
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Local Collection View

    @ViewBuilder
    private var localCollectionView: some View {
        if localCollection.isEmpty {
            emptyStateView
        } else {
            List(selection: $selection) {
                ForEach(localCollection) { collection in
                    MacLocalCollectionRow(collection: collection)
                        .tag(collection)
                        .contextMenu {
                            Button {
                                localItemToEdit = collection
                            } label: {
                                Label("action_edit", systemImage: "pencil")
                            }

                            Divider()

                            Button("action_delete", role: .destructive) {
                                modelContext.delete(collection)
                                try? modelContext.save()
                            }
                        }
                }
                .onDelete(perform: deleteLocalMangas)
            }
            .listStyle(.plain)
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "collection_empty_title",
            systemImage: "books.vertical",
            description: Text("collection_empty_description")
        )
    }

    private func deleteLocalMangas(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(localCollection[index])
        }
        try? modelContext.save()
    }
}

// MARK: - Local Collection Row

struct MacLocalCollectionRow: View {
    let collection: UserCollection

    var body: some View {
        HStack(spacing: 12) {
            // Miniatura
            CachedCoverImage(
                url: URL(string: collection.mainPicture.replacingOccurrences(of: "\"", with: "")),
                width: 40,
                height: 60
            )

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.title)
                    .font(.headline)
                    .lineLimit(1)

                if let english = collection.titleEnglish {
                    Text(english)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption2)

                    Text(String(format: "%.2f", collection.score))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if collection.hasCompleteCollection {
                        Text("separator_dot")
                            .foregroundStyle(.secondary)
                        Label("collection_complete", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else if let total = collection.totalVolumes {
                        Text("separator_dot")
                            .foregroundStyle(.secondary)
                        Text("volumes_owned_of \(collection.volumesOwned.count) \(total)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Edit Cloud Collection View
struct MacEditCollectionView: View {
    let collectionItem: UserMangaCollection

    @Environment(\.dismiss) private var dismiss
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    @State private var selectedVolumes: Set<Int>
    @State private var currentReadingVolume: Int
    @State private var hasCompleteCollection: Bool
    @State private var isSaving = false

    init(collectionItem: UserMangaCollection) {
        self.collectionItem = collectionItem
        _selectedVolumes = State(initialValue: Set(collectionItem.volumesOwned))
        _currentReadingVolume = State(initialValue: collectionItem.readingVolume ?? 1)
        _hasCompleteCollection = State(initialValue: collectionItem.completeCollection)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("action_edit")
                .font(.title.bold())

            CachedCoverImage(
                url: URL(string: collectionItem.manga.mainPicture.replacingOccurrences(of: "\"", with: "")),
                width: 150,
                height: 225
            )

            Text(collectionItem.manga.title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Form {
                Toggle("add_complete_collection", isOn: $hasCompleteCollection)
                    .onChange(of: hasCompleteCollection) { _, newValue in
                        if newValue, let totalVolumes = collectionItem.manga.volumes {
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

                Stepper("collection_reading_volume \(currentReadingVolume)", value: $currentReadingVolume, in: 1...(collectionItem.manga.volumes ?? 100))
            }
            .padding()

            Spacer()

            HStack {
                Button("action_cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("action_save") {
                    Task {
                        await saveChanges()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
            }
            .padding()
        }
        .padding()
        .frame(width: 500, height: 600)
    }

    private func saveChanges() async {
        isSaving = true

        // Primero eliminar el item actual
        try? await cloudVM.removeFromCollection(mangaId: collectionItem.manga.id)

        // Luego añadir con los nuevos valores
        try? await cloudVM.addToCollection(
            manga: collectionItem.manga,
            volumesOwned: Array(selectedVolumes).sorted(),
            readingVolume: currentReadingVolume,
            completeCollection: hasCompleteCollection
        )

        isSaving = false
        dismiss()
    }
}

// MARK: - Edit Local Collection View
struct MacEditLocalCollectionView: View {
    @Bindable var collection: UserCollection

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedVolumes: Set<Int>
    @State private var currentReadingVolume: Int
    @State private var hasCompleteCollection: Bool

    init(collection: UserCollection) {
        self.collection = collection
        _selectedVolumes = State(initialValue: Set(collection.volumesOwned))
        _currentReadingVolume = State(initialValue: collection.currentReadingVolume ?? 1)
        _hasCompleteCollection = State(initialValue: collection.hasCompleteCollection)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("action_edit")
                .font(.title.bold())

            CachedCoverImage(
                url: URL(string: collection.mainPicture.replacingOccurrences(of: "\"", with: "")),
                width: 150,
                height: 225
            )

            Text(collection.title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Form {
                Toggle("add_complete_collection", isOn: $hasCompleteCollection)
                    .onChange(of: hasCompleteCollection) { _, newValue in
                        if newValue, let totalVolumes = collection.totalVolumes {
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

                Stepper("collection_reading_volume \(currentReadingVolume)", value: $currentReadingVolume, in: 1...(collection.totalVolumes ?? 100))
            }
            .padding()

            Spacer()

            HStack {
                Button("action_cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("action_save") {
                    saveChanges()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .padding()
        .frame(width: 500, height: 600)
    }

    private func saveChanges() {
        collection.volumesOwned = Array(selectedVolumes).sorted()
        collection.currentReadingVolume = currentReadingVolume
        collection.hasCompleteCollection = hasCompleteCollection
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    MacCollectionView(selection: .constant(nil))
        .environment(AuthViewModel())
        .environment(CloudCollectionViewModel(authVM: AuthViewModel()))
        .modelContainer(.preview)
}
