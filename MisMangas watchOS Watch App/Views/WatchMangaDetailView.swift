//
//  WatchMangaDetailView.swift
//  MisMangas watchOS Watch App
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI
import WatchKit

struct WatchMangaDetailView: View {
    let item: UserMangaCollection
    let onSave: () -> Void

    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.dismiss) private var dismiss

    @State private var currentVolume: Int
    @State private var volumesOwned: Int
    @State private var isSaving = false

    init(item: UserMangaCollection, onSave: @escaping () -> Void = {}) {
        self.item = item
        self.onSave = onSave
        _currentVolume = State(initialValue: item.readingVolume ?? 0)
        _volumesOwned = State(initialValue: item.volumesOwned.count)
    }

    private var updatedItem: UserMangaCollection {
        cloudVM.cloudCollection.first(where: { $0.id == item.id }) ?? item
    }

    private var hasChanges: Bool {
        currentVolume != updatedItem.readingVolume || volumesOwned != updatedItem.volumesOwned.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                headerSection
                Divider()
                volumesOwnedSection
                readingVolumeSection
                progressSection
                Divider()
                saveButton
            }
            .padding()
        }
        .navigationTitle("nav_detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var headerSection: some View {
        Group {
            Text(updatedItem.manga.title)
                .font(.headline)

            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text(updatedItem.manga.score.formatted(.number.precision(.fractionLength(2))))
            }
            .font(.caption)
        }
    }

    private var volumesOwnedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("edit_volumes_owned")
                .font(.caption)
                .foregroundStyle(.secondary)

            Stepper(value: $volumesOwned, in: 0...(updatedItem.manga.volumes ?? 999)) {
                Text("volumes_owned_count \(volumesOwned)")
                    .font(.title3.bold())
            }
        }
    }

    private var readingVolumeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("add_reading_volume")
                .font(.caption)
                .foregroundStyle(.secondary)

            Stepper(value: $currentVolume, in: 0...(updatedItem.manga.volumes ?? 999)) {
                Text("vol_current \(currentVolume)")
                    .font(.title3.bold())
            }
        }
    }

    private var progressSection: some View {
        Group {
            if let total = updatedItem.manga.volumes, total > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("edit_progress_section")
                            .font(.caption)
                        Spacer()
                        Text("progress_percent \(Int((Double(currentVolume) / Double(total)) * 100))")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)

                    ProgressView(value: Double(currentVolume), total: Double(total))
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task { await saveProgress() }
        } label: {
            if isSaving {
                ProgressView()
            } else {
                Label("action_save", systemImage: "checkmark.circle.fill")
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isSaving || !hasChanges)
    }

    // MARK: - Actions

    private func saveProgress() async {
        isSaving = true
        let ownedArray = volumesOwned > 0 ? Array(1...volumesOwned) : []

        do {
            try await cloudVM.addToCollection(
                manga: updatedItem.manga,
                volumesOwned: ownedArray,
                readingVolume: currentVolume,
                completeCollection: updatedItem.completeCollection
            )
            WKInterfaceDevice.current().play(.success)
            onSave()
            try? await Task.sleep(for: .milliseconds(150))
            dismiss()
        } catch {
            WKInterfaceDevice.current().play(.failure)
        }

        isSaving = false
    }
}

#Preview {
    let authVM = AuthViewModel()
    NavigationStack {
        WatchMangaDetailView(item: .test)
            .environment(CloudCollectionViewModel(authVM: authVM))
    }
}
