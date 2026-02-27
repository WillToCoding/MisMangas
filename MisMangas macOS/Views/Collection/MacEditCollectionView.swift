//
//  MacEditCollectionView.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

/// Vista de edición para items de colección cloud
struct MacEditCollectionView: View {
    let collectionItem: UserMangaCollection

    @Environment(\.dismiss) private var dismiss
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    @State private var volumesOwnedCount: Double
    @State private var currentReadingVolume: Double
    @State private var isSaving = false

    private var totalVolumes: Int {
        collectionItem.manga.volumes ?? 50
    }

    init(collectionItem: UserMangaCollection) {
        self.collectionItem = collectionItem
        _volumesOwnedCount = State(initialValue: Double(collectionItem.volumesOwned.count))
        _currentReadingVolume = State(initialValue: Double(collectionItem.readingVolume ?? 1))
    }

    var body: some View {
        VStack(spacing: 20) {
            headerSection
            Divider().padding(.horizontal, 24)
            ongoingInfoSection
            slidersSection
            Spacer()
            buttonsSection
        }
        .frame(minWidth: 480, minHeight: 480)
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack(spacing: 20) {
            CachedCoverImage(
                url: collectionItem.manga.coverURL,
                width: 100,
                height: 150
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(collectionItem.manga.title)
                    .font(.title.bold())
                    .lineLimit(2)

                volumeInfo

                if collectionItem.manga.score > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text(collectionItem.manga.score.formatted(.number.precision(.fractionLength(1))))
                    }
                    .font(.body)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var volumeInfo: some View {
        Group {
            if let total = collectionItem.manga.volumes {
                Text("\(total) volumes")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text("status_publishing")
                }
                .font(.body)
                .foregroundStyle(.orange)
            }
        }
    }

    private var ongoingInfoSection: some View {
        Group {
            if collectionItem.manga.volumes == nil {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.orange)
                    Text("edit_ongoing_manga")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var slidersSection: some View {
        VStack(spacing: 28) {
            // Volúmenes en propiedad
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("edit_volumes_owned", systemImage: "books.vertical.fill")
                        .font(.headline)
                    Spacer()

                    HStack(spacing: 4) {
                        TextField("", value: $volumesOwnedCount, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                            .multilineTextAlignment(.center)

                        if let total = collectionItem.manga.volumes {
                            Text("/ \(total)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.title3.bold().monospacedDigit())
                }

                Slider(value: $volumesOwnedCount, in: 0...Double(totalVolumes), step: 1)
                    .tint(.blue)
            }

            // Volumen de lectura actual
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("edit_reading_volume", systemImage: "bookmark.fill")
                        .font(.headline)
                    Spacer()

                    HStack(spacing: 4) {
                        TextField("", value: $currentReadingVolume, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                            .multilineTextAlignment(.center)

                        if let total = collectionItem.manga.volumes {
                            Text("/ \(total)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.title3.bold().monospacedDigit())
                }

                Slider(value: $currentReadingVolume, in: 1...max(1, Double(totalVolumes), volumesOwnedCount), step: 1)
                    .tint(.orange)
            }
        }
        .padding(.horizontal, 24)
    }

    private var buttonsSection: some View {
        HStack(spacing: 16) {
            Button("action_cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button("action_save") {
                Task {
                    await saveChanges()
                }
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isSaving)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
    }

    // MARK: - Actions

    private func saveChanges() async {
        isSaving = true

        let ownedCount = Int(volumesOwnedCount)
        let volumes = ownedCount > 0 ? Array(1...ownedCount) : []
        let readingVol = Int(currentReadingVolume)

        do {
            try await cloudVM.addToCollection(
                manga: collectionItem.manga,
                volumesOwned: volumes,
                readingVolume: readingVol,
                completeCollection: collectionItem.completeCollection
            )
        } catch {
            print("Error guardando en cloud: \(error)")
        }

        isSaving = false
        dismiss()
    }
}

#Preview {
    MacEditCollectionView(collectionItem: .test)
        .environment(CloudCollectionViewModel(authVM: AuthViewModel()))
}
