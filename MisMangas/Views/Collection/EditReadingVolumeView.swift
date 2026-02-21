//
//  EditReadingVolumeView.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI

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
                CachedCoverImage(
                    url: URL(string: item.manga.mainPicture.replacingOccurrences(of: "\"", with: ""))
                )
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

#Preview {
    EditReadingVolumeView(item: .init(
        id: "1",
        manga: .test,
        completeCollection: false,
        volumesOwned: [1, 2, 3],
        readingVolume: 2
    ))
}
