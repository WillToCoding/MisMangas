//
//  CollectionView.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI
import SwiftData

struct CollectionView: View {
    @Query(sort: \Model.addedDate, order: .reverse) private var localCollection: [Model]
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    @State private var showDeleteAlert = false
    @State private var mangaToDelete: Int?
    @State private var selectedMangaForEdit: UserMangaCollection?

    var body: some View {
        NavigationStack {
            Group {
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
            .refreshable {
                if authVM.isAuthenticated {
                    await cloudVM.loadCollection()
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
        }
    }

    // MARK: - Cloud Collection View

    @ViewBuilder
    private var cloudCollectionView: some View {
        if cloudVM.isLoading {
            ProgressView("loading_collection")
        } else if let error = cloudVM.errorMessage {
            ContentUnavailableView(
                "error_loading",
                systemImage: "exclamationmark.triangle",
                description: Text(error)
            )
        } else if cloudVM.cloudCollection.isEmpty {
            emptyStateView
        } else {
            List {
                ForEach(cloudVM.cloudCollection) { item in
                    CloudCollectionRow(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedMangaForEdit = item
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                mangaToDelete = item.manga.id
                                showDeleteAlert = true
                            } label: {
                                Label("action_delete", systemImage: "trash")
                            }
                        }
                }
            }
            .sheet(item: $selectedMangaForEdit) { item in
                EditReadingVolumeView(item: item)
            }
            .toolbar {
                if !cloudVM.cloudCollection.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Label("collection_cloud_label", systemImage: "cloud.fill")
                            .foregroundStyle(.blue)
                            .font(.caption)
                    }
                }
            }
        }
    }

    // MARK: - Local Collection View

    @ViewBuilder
    private var localCollectionView: some View {
        if localCollection.isEmpty {
            emptyStateView
        } else {
            List {
                ForEach(localCollection) { manga in
                    LocalCollectionRow(manga: manga)
                }
                .onDelete(perform: deleteLocalMangas)
            }
            .toolbar {
                if !localCollection.isEmpty {
                    EditButton()
                }
            }
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

struct LocalCollectionRow: View {
    let manga: Model

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: manga.mainPicture.replacingOccurrences(of: "\"", with: ""))) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(manga.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                    Text(String(format: "%.2f", manga.score))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if manga.hasCompleteCollection {
                    Label("collection_complete", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("volumes_owned_of \(manga.volumesOwned.count) \(manga.totalVolumes.map(String.init) ?? "?")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let currentReading = manga.currentReadingVolume {
                    Label("vol_current \(currentReading)", systemImage: "book.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Cloud Collection Row

struct CloudCollectionRow: View {
    let item: UserMangaCollection

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: item.manga.mainPicture.replacingOccurrences(of: "\"", with: ""))) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.manga.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                    Text(String(format: "%.2f", item.manga.score))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if item.completeCollection {
                    Label("collection_complete", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("volumes_owned_of \(item.volumesOwned.count) \(item.manga.volumes ?? 0)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let currentReading = item.readingVolume {
                    Label("vol_current \(currentReading)", systemImage: "book.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }

                HStack(spacing: 4) {
                    Image(systemName: "cloud.fill")
                        .font(.caption2)
                    Text("collection_cloud")
                        .font(.caption2)
                }
                .foregroundStyle(.blue.opacity(0.7))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Edit Reading Volume View

struct EditReadingVolumeView: View {
    let item: UserMangaCollection

    @Environment(\.dismiss) private var dismiss
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    @State private var readingVolume: Int
    @State private var isSaving = false

    init(item: UserMangaCollection) {
        self.item = item
        _readingVolume = State(initialValue: item.readingVolume ?? 1)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        AsyncImage(url: URL(string: item.manga.mainPicture.replacingOccurrences(of: "\"", with: ""))) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 60, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading) {
                            Text(item.manga.title)
                                .font(.headline)
                            if let volumes = item.manga.volumes {
                                Text("stats_vols \(volumes)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("edit_progress_section") {
                    Stepper("vol_current \(readingVolume)", value: $readingVolume, in: 1...(item.manga.volumes ?? 999))

                    if let total = item.manga.volumes {
                        ProgressView(value: Double(readingVolume), total: Double(total))
                        Text("progress_percent \(Int((Double(readingVolume) / Double(total)) * 100))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("nav_edit_progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action_cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("action_save") {
                        Task {
                            await saveProgress()
                        }
                    }
                    .disabled(isSaving || readingVolume == item.readingVolume)
                }
            }
        }
    }

    private func saveProgress() async {
        isSaving = true

        do {
            try await cloudVM.addToCollection(
                manga: item.manga,
                volumesOwned: item.volumesOwned,
                readingVolume: readingVolume,
                completeCollection: item.completeCollection
            )
            dismiss()
        } catch {
            print("Error guardando progreso: \(error)")
        }

        isSaving = false
    }
}

#Preview {
    CollectionView()
        .modelContainer(.preview)
}
