//
//  iPadEditCollectionView.swift
//  MisMangas
//
//  Created by Juan Carlos on 23/2/26.
//

import SwiftUI
import SwiftData

// MARK: - iPad Edit Cloud Collection View

struct iPadEditCollectionView: View {
    let item: UserMangaCollection

    @Environment(\.dismiss) private var dismiss
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    @State private var volumesOwnedCount: Double
    @State private var readingVolume: Double
    @State private var isSaving = false

    private var totalVolumes: Int {
        item.manga.volumes ?? 50
    }

    init(item: UserMangaCollection) {
        self.item = item
        _volumesOwnedCount = State(initialValue: Double(item.volumesOwned.count))
        _readingVolume = State(initialValue: Double(item.readingVolume ?? 1))
    }

    var body: some View {
        NavigationStack {
            Form {
                mangaInfoSection
                volumesOwnedSection
                readingVolumeSection
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
                    .disabled(isSaving)
                }
            }
        }
    }

    // MARK: - Manga Info Section

    private var mangaInfoSection: some View {
        Section {
            HStack(spacing: 16) {
                CachedCoverImage(url: item.manga.coverURL, width: 80, height: 120)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.manga.title)
                        .font(.title3.bold())
                        .lineLimit(2)

                    if let volumes = item.manga.volumes {
                        Text("stats_vols \(volumes)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("edit_ongoing_manga", systemImage: "info.circle")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Volumes Owned Section

    private var volumesOwnedSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("edit_volumes_owned", systemImage: "books.vertical.fill")
                        .font(.headline)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("\(Int(volumesOwnedCount))")
                            .font(.title2.bold().monospacedDigit())
                            .foregroundStyle(.blue)

                        if let total = item.manga.volumes {
                            Text("/ \(total)")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Slider(value: $volumesOwnedCount, in: 0...Double(totalVolumes), step: 1)
                    .tint(.blue)

                if let total = item.manga.volumes {
                    ProgressView(value: volumesOwnedCount, total: Double(total))
                        .tint(.blue)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("edit_collection_section")
        }
    }

    // MARK: - Reading Volume Section

    private var readingVolumeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("edit_reading_volume", systemImage: "bookmark.fill")
                        .font(.headline)

                    Spacer()

                    Text("\(Int(readingVolume))")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(.orange)
                }

                Slider(
                    value: $readingVolume,
                    in: 1...max(1, Double(totalVolumes), volumesOwnedCount),
                    step: 1
                )
                .tint(.orange)

                if let total = item.manga.volumes {
                    HStack {
                        ProgressView(value: readingVolume, total: Double(total))
                            .tint(.orange)

                        Text("progress_percent \(Int((readingVolume / Double(total)) * 100))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("edit_progress_section")
        }
    }

    // MARK: - Actions

    private func saveProgress() async {
        isSaving = true

        let ownedCount = Int(volumesOwnedCount)
        let volumes = ownedCount > 0 ? Array(1...ownedCount) : []
        let readingVol = Int(readingVolume)
        let isComplete = ownedCount == totalVolumes

        do {
            try await cloudVM.addToCollection(
                manga: item.manga,
                volumesOwned: volumes,
                readingVolume: readingVol,
                completeCollection: isComplete
            )
            dismiss()
        } catch {
            print("Error guardando: \(error)")
        }

        isSaving = false
    }
}

// MARK: - iPad Edit Local Collection View

struct iPadEditLocalCollectionView: View {
    @Bindable var collection: UserCollection

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var volumesOwnedCount: Double
    @State private var readingVolume: Double
    @State private var hasCompleteCollection: Bool

    private var totalVolumes: Int {
        collection.totalVolumes ?? 50
    }

    init(collection: UserCollection) {
        self.collection = collection
        _volumesOwnedCount = State(initialValue: Double(collection.volumesOwned.count))
        _readingVolume = State(initialValue: Double(collection.currentReadingVolume ?? 1))
        _hasCompleteCollection = State(initialValue: collection.hasCompleteCollection)
    }

    var body: some View {
        NavigationStack {
            Form {
                mangaInfoSection
                volumesOwnedSection
                readingVolumeSection
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
                        saveChanges()
                    }
                }
            }
        }
    }

    // MARK: - Manga Info Section

    private var mangaInfoSection: some View {
        Section {
            HStack(spacing: 16) {
                CachedCoverImage(url: collection.collectionCoverURL, width: 80, height: 120)

                VStack(alignment: .leading, spacing: 4) {
                    Text(collection.title)
                        .font(.title3.bold())
                        .lineLimit(2)

                    if let volumes = collection.totalVolumes {
                        Text("stats_vols \(volumes)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("edit_ongoing_manga", systemImage: "info.circle")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Volumes Owned Section

    private var volumesOwnedSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("edit_volumes_owned", systemImage: "books.vertical.fill")
                        .font(.headline)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("\(Int(volumesOwnedCount))")
                            .font(.title2.bold().monospacedDigit())
                            .foregroundStyle(.blue)

                        if let total = collection.totalVolumes {
                            Text("/ \(total)")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Slider(value: $volumesOwnedCount, in: 0...Double(totalVolumes), step: 1)
                    .tint(.blue)
                    .onChange(of: volumesOwnedCount) { _, newValue in
                        hasCompleteCollection = Int(newValue) == totalVolumes
                    }

                if let total = collection.totalVolumes {
                    ProgressView(value: volumesOwnedCount, total: Double(total))
                        .tint(.blue)
                }

                Toggle("add_complete_collection", isOn: $hasCompleteCollection)
                    .onChange(of: hasCompleteCollection) { _, newValue in
                        if newValue {
                            volumesOwnedCount = Double(totalVolumes)
                        }
                    }
            }
            .padding(.vertical, 8)
        } header: {
            Text("edit_collection_section")
        }
    }

    // MARK: - Reading Volume Section

    private var readingVolumeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("edit_reading_volume", systemImage: "bookmark.fill")
                        .font(.headline)

                    Spacer()

                    Text("\(Int(readingVolume))")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(.orange)
                }

                Slider(
                    value: $readingVolume,
                    in: 1...max(1, Double(totalVolumes), volumesOwnedCount),
                    step: 1
                )
                .tint(.orange)

                if let total = collection.totalVolumes {
                    HStack {
                        ProgressView(value: readingVolume, total: Double(total))
                            .tint(.orange)

                        Text("progress_percent \(Int((readingVolume / Double(total)) * 100))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("edit_progress_section")
        }
    }

    // MARK: - Actions

    private func saveChanges() {
        Task {
            let dataContainer = DataContainer(modelContainer: modelContext.container)
            let ownedCount = Int(volumesOwnedCount)
            let volumes = ownedCount > 0 ? Array(1...ownedCount) : []

            do {
                try await dataContainer.updateUserStats(
                    mangaId: collection.manga.id,
                    currentVolume: Int(readingVolume),
                    volumesOwned: volumes,
                    hasCompleteCollection: hasCompleteCollection
                )
            } catch {
                print("Error guardando cambios: \(error)")
            }
            dismiss()
        }
    }
}

#Preview {
    iPadEditCollectionView(item: .init(
        id: "1",
        manga: .test,
        completeCollection: false,
        volumesOwned: [1, 2, 3],
        readingVolume: 2
    ))
}
