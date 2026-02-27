//
//  EditLocalCollectionView.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI
import SwiftData

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
                mangaInfoSection
                collectionSection
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
                        saveChanges()
                    }
                    .accessibilityHint(String(localized: "accessibility_save_progress_hint"))
                }
            }
        }
    }

    // MARK: - Manga Info Section

    private var mangaInfoSection: some View {
        Section {
            HStack {
                CachedCoverImage(url: collection.collectionCoverURL)
                    .accessibilityHidden(true)

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
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(collection.title), \(collection.totalVolumes ?? 0) " + String(localized: "accessibility_total_volumes"))
        }
    }

    // MARK: - Collection Section

    private var collectionSection: some View {
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
                .accessibilityHint(String(localized: "accessibility_complete_collection_hint"))

            if !hasCompleteCollection {
                HStack {
                    Text("detail_volumes")
                    Spacer()
                    Text("\(selectedVolumes.count)")
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "accessibility_volumes_owned_count \(selectedVolumes.count)"))
            }
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        Section("edit_progress_section") {
            HStack {
                Text("edit_reading_volume")
                Spacer()
                HStack(spacing: 4) {
                    Text("\(currentReadingVolume)")
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                    if let total = collection.totalVolumes {
                        Text("/ \(total)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "accessibility_current_volume"))
            .accessibilityValue("\(currentReadingVolume)")

            Stepper("", value: $currentReadingVolume, in: 1...(collection.totalVolumes ?? 100))
                .labelsHidden()
                .accessibilityHint(String(localized: "accessibility_stepper_hint"))
                .onChange(of: currentReadingVolume) { _, _ in
                    #if os(iOS)
                    HapticFeedback.selection.trigger()
                    #endif
                }

            if let total = collection.totalVolumes {
                ProgressView(value: Double(currentReadingVolume), total: Double(total))
                    .tint(.orange)
                    .accessibilityLabel(String(localized: "accessibility_reading_progress"))
                    .accessibilityValue("\(Int((Double(currentReadingVolume) / Double(total)) * 100))%")
            }
        }
    }

    // MARK: - Actions

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

#Preview(traits: .sampleData) {
    EditLocalCollectionView(collection: PreviewData.shared.sampleCollection)
}
