//
//  EditReadingVolumeView.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI
import SwiftData

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
                mangaInfoSection
                progressSection
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
                    .accessibilityHint(String(localized: "accessibility_save_progress_hint"))
                }
            }
        }
    }

    // MARK: - Manga Info Section
    private var mangaInfoSection: some View {
        Section {
            HStack {
                CachedCoverImage(url: item.manga.coverURL)
                .accessibilityHidden(true)

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
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(item.manga.title), \(item.manga.volumes ?? 0) " + String(localized: "accessibility_total_volumes"))
        }
    }

    // MARK: - Progress Section
    private var progressSection: some View {
        Section("edit_progress_section") {
            Stepper("vol_current \(readingVolume)", value: $readingVolume, in: 1...(item.manga.volumes ?? 999))
                .accessibilityLabel(String(localized: "accessibility_current_volume"))
                .accessibilityValue("\(readingVolume)")
                .accessibilityHint(String(localized: "accessibility_stepper_hint"))
                .onChange(of: readingVolume) { _, _ in
                    #if os(iOS)
                    HapticFeedback.selection.trigger()
                    #endif
                }

            if let total = item.manga.volumes {
                ProgressView(value: Double(readingVolume), total: Double(total))
                    .accessibilityLabel(String(localized: "accessibility_reading_progress"))
                    .accessibilityValue("\(Int((Double(readingVolume) / Double(total)) * 100))%")

                Text("progress_percent \(Int((Double(readingVolume) / Double(total)) * 100))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }

    // MARK: - Actions
    private func saveProgress() async {
        isSaving = true

        do {
            try await cloudVM.addToCollection(
                manga: item.manga,
                volumesOwned: item.volumesOwned,
                readingVolume: readingVolume,
                completeCollection: item.completeCollection
            )
            #if os(iOS)
            HapticFeedback.success.trigger()
            #endif
            dismiss()
        } catch {
            print("Error guardando progreso: \(error)")
            #if os(iOS)
            HapticFeedback.error.trigger()
            #endif
        }

        isSaving = false
    }
}

// MARK: - Edit Local Collection View (iPhone)

struct EditLocalCollectionView: View {
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
        NavigationStack {
            Form {
                // Info
                Section {
                    HStack {
                        CachedCoverImage(url: collection.collectionCoverURL)

                        VStack(alignment: .leading) {
                            Text(collection.title)
                                .font(.headline)
                            if let volumes = collection.totalVolumes {
                                Text("stats_vols \(volumes)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Colección
                Section("edit_collection_section") {
                    Toggle("add_complete_collection", isOn: $hasCompleteCollection)
                        .onChange(of: hasCompleteCollection) { _, newValue in
                            if newValue, let totalVolumes = collection.totalVolumes {
                                selectedVolumes = Set(1...totalVolumes)
                            }
                            #if os(iOS)
                            HapticFeedback.selection.trigger()
                            #endif
                        }

                    if !hasCompleteCollection {
                        HStack {
                            Text("detail_volumes")
                            Spacer()
                            Text("\(selectedVolumes.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Progreso
                Section("edit_progress_section") {
                    Stepper("vol_current \(currentReadingVolume)", value: $currentReadingVolume, in: 1...(collection.totalVolumes ?? 100))
                        .onChange(of: currentReadingVolume) { _, _ in
                            #if os(iOS)
                            HapticFeedback.selection.trigger()
                            #endif
                        }

                    if let total = collection.totalVolumes {
                        ProgressView(value: Double(currentReadingVolume), total: Double(total))

                        Text("progress_percent \(Int((Double(currentReadingVolume) / Double(total)) * 100))")
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
                        saveChanges()
                    }
                }
            }
        }
    }

    private func saveChanges() {
        Task {
            let dataContainer = DataContainer(modelContainer: modelContext.container)
            do {
                try await dataContainer.updateUserStats(
                    mangaId: collection.manga.id,
                    currentVolume: currentReadingVolume,
                    volumesOwned: Array(selectedVolumes).sorted(),
                    hasCompleteCollection: hasCompleteCollection
                )
                #if os(iOS)
                HapticFeedback.success.trigger()
                #endif
            } catch {
                print("Error guardando cambios: \(error)")
                #if os(iOS)
                HapticFeedback.error.trigger()
                #endif
            }
            dismiss()
        }
    }
}

#Preview {
    EditReadingVolumeView(item: .init(
        id: "1",
        manga: .test,
        completeCollection: false,
        volumesOwned: [1, 2, 3],
        readingVolume: 2
    ))
}
