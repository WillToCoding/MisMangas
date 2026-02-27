//
//  iPadEditCollectionView.swift
//  MisMangas
//
//  Created by Juan Carlos on 23/2/26.
//

import SwiftUI
import SwiftData

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
                    .accessibilityHidden(true)

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
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(item.manga.title), \(item.manga.volumes ?? 0) " + String(localized: "accessibility_total_volumes"))
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "accessibility_volumes_owned_count \(Int(volumesOwnedCount))"))

                Slider(value: $volumesOwnedCount, in: 0...Double(totalVolumes), step: 1)
                    .tint(.blue)
                    .accessibilityLabel(String(localized: "edit_volumes_owned"))
                    .accessibilityValue("\(Int(volumesOwnedCount))")
            }
            .padding(.vertical, 8)
        } header: {
            Text("edit_collection_section")
                .accessibilityHeader()
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

                    HStack(spacing: 4) {
                        Text("\(Int(readingVolume))")
                            .font(.title2.bold().monospacedDigit())
                            .foregroundStyle(.orange)

                        if let total = item.manga.volumes {
                            Text("/ \(total)")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "accessibility_current_volume"))
                .accessibilityValue("\(Int(readingVolume))")

                Slider(
                    value: $readingVolume,
                    in: 1...max(1, Double(totalVolumes), volumesOwnedCount),
                    step: 1
                )
                .tint(.orange)
                .accessibilityLabel(String(localized: "edit_reading_volume"))
                .accessibilityValue("\(Int(readingVolume))")
            }
            .padding(.vertical, 8)
        } header: {
            Text("edit_progress_section")
                .accessibilityHeader()
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

#Preview(traits: .sampleData) {
    iPadEditCollectionView(item: .test)
}
