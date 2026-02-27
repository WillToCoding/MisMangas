//
//  MacAddToCollectionView.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI
import SwiftData

/// Vista para añadir un manga a la colección
struct MacAddToCollectionView: View {
    let manga: Manga

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    @State private var volumesOwnedCount: Double = 1
    @State private var currentReadingVolume: Double = 1
    @State private var isSaving = false

    private var totalVolumes: Int {
        manga.volumes ?? 50
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
                url: manga.coverURL,
                width: 100,
                height: 150
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(manga.title)
                    .font(.title.bold())
                    .lineLimit(2)

                volumeInfo

                if manga.score > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text(manga.score.formatted(.number.precision(.fractionLength(1))))
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
            if let total = manga.volumes {
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
            if manga.volumes == nil {
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

                        if let total = manga.volumes {
                            Text("/ \(total)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.title3.bold().monospacedDigit())
                }

                Slider(value: $volumesOwnedCount, in: 0...Double(totalVolumes), step: 1)
                    .tint(.blue)
            }

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

                        if let total = manga.volumes {
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

            Button("action_add") {
                Task { await saveToCollection() }
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

    private func saveToCollection() async {
        isSaving = true

        let ownedCount = Int(volumesOwnedCount)
        let volumes = ownedCount > 0 ? Array(1...ownedCount) : []
        let readingVol = Int(currentReadingVolume)
        let isComplete = ownedCount == totalVolumes

        let dataContainer = DataContainer(modelContainer: modelContext.container)
        do {
            try await dataContainer.addToCollection(
                manga: manga,
                volumesOwned: volumes,
                currentReadingVolume: readingVol,
                hasCompleteCollection: isComplete
            )
        } catch {
            print("Error al guardar en local: \(error)")
            isSaving = false
            return
        }

        if authVM.isAuthenticated {
            do {
                try await cloudVM.addToCollection(
                    manga: manga,
                    volumesOwned: volumes,
                    readingVolume: readingVol,
                    completeCollection: isComplete
                )
            } catch {
                print("Error al guardar en cloud: \(error)")
            }
        }

        isSaving = false
        dismiss()
    }
}

#Preview {
    MacAddToCollectionView(manga: .test)
        .environment(AuthViewModel())
        .environment(CloudCollectionViewModel(authVM: AuthViewModel()))
        .modelContainer(.preview)
}
