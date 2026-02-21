//
//  AddToCollectionView.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI
import SwiftData

struct AddToCollectionView: View {
    let manga: Manga

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    @State private var selectedVolumes: Set<Int> = []
    @State private var currentReadingVolume: Int = 1
    @State private var currentChapter: Int = 1
    @State private var hasCompleteCollection = false
    @State private var readingStatus: ReadingStatus = .planToRead
    @State private var userScore: Double?
    @State private var showSuccess = false
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Manga") {
                    HStack {
                        CachedCoverImage(
                            url: URL(string: manga.mainPicture.replacingOccurrences(of: "\"", with: ""))
                        )
                        .accessibilityHidden(true)

                        VStack(alignment: .leading) {
                            Text(manga.title)
                                .font(.headline)
                            if let volumes = manga.volumes {
                                Text("stats_vols \(volumes)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(manga.title), \(manga.volumes ?? 0) " + String(localized: "accessibility_total_volumes"))
                }

                Section("section_collection") {
                    Toggle("add_complete_collection", isOn: $hasCompleteCollection)
                        .onChange(of: hasCompleteCollection) { _, newValue in
                            if newValue, let totalVolumes = manga.volumes {
                                selectedVolumes = Set(1...totalVolumes)
                            }
                        }
                        .accessibilityHint(String(localized: "accessibility_complete_collection_hint"))
                }

                if let totalVolumes = manga.volumes, !hasCompleteCollection {
                    Section("section_volumes_owned") {
                        ForEach(1...totalVolumes, id: \.self) { volume in
                            Toggle("volume_number \(volume)", isOn: Binding(
                                get: { selectedVolumes.contains(volume) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedVolumes.insert(volume)
                                    } else {
                                        selectedVolumes.remove(volume)
                                    }
                                }
                            ))
                            .accessibilityHint(selectedVolumes.contains(volume) ? String(localized: "accessibility_volume_owned") : String(localized: "accessibility_volume_not_owned"))
                        }
                    }
                }

                if !selectedVolumes.isEmpty {
                    Section("section_reading_progress") {
                        Stepper("vol_current \(currentReadingVolume)", value: $currentReadingVolume, in: 1...(manga.volumes ?? 100))
                            .accessibilityLabel(String(localized: "accessibility_current_volume"))
                            .accessibilityValue("\(currentReadingVolume)")
                            .accessibilityHint(String(localized: "accessibility_stepper_hint"))

                        if manga.chapters != nil {
                            Stepper("chapter_current \(currentChapter)", value: $currentChapter, in: 1...(manga.chapters ?? 9999))
                        }
                    }
                }

                Section("section_my_status") {
                    Picker("reading_status_label", selection: $readingStatus) {
                        ForEach(ReadingStatus.allCases, id: \.self) { status in
                            Label(status.localizedName, systemImage: status.icon)
                                .tag(status)
                        }
                    }

                    Toggle("add_my_score", isOn: Binding(
                        get: { userScore != nil },
                        set: { userScore = $0 ? 7.0 : nil }
                    ))

                    if userScore != nil {
                        HStack {
                            Text(String(format: "%.1f", userScore ?? 7.0))
                                .font(.headline)
                                .foregroundStyle(.yellow)
                            Slider(value: Binding(
                                get: { userScore ?? 7.0 },
                                set: { userScore = $0 }
                            ), in: 1...10, step: 0.5)
                        }
                    }
                }
            }
            .navigationTitle("nav_add_collection")
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
                            await saveToCollection()
                        }
                    }
                    .disabled(selectedVolumes.isEmpty && !hasCompleteCollection || isSaving)
                    .accessibilityLabel(String(localized: "accessibility_save_to_collection"))
                    .accessibilityHint(String(localized: "accessibility_save_collection_hint"))
                }
            }
            .alert("saved_title", isPresented: $showSuccess) {
                Button("action_ok") {
                    dismiss()
                }
            } message: {
                Text("add_success_message")
            }
        }
    }

    private func saveToCollection() async {
        isSaving = true
        let volumes = Array(selectedVolumes).sorted()

        // Guardar en local usando DataContainer (background)
        let dataContainer = DataContainer(modelContainer: modelContext.container)
        do {
            try await dataContainer.addToCollection(
                manga: manga,
                volumesOwned: volumes,
                currentReadingVolume: currentReadingVolume,
                currentChapter: manga.chapters != nil ? currentChapter : nil,
                hasCompleteCollection: hasCompleteCollection,
                userScore: userScore,
                readingStatus: readingStatus
            )
        } catch {
            print("Error al guardar en local: \(error)")
            #if os(iOS)
            HapticFeedback.error.trigger()
            #endif
            isSaving = false
            return
        }

        // Si está logueado, también guardar en cloud
        if authVM.isAuthenticated {
            do {
                try await cloudVM.addToCollection(
                    manga: manga,
                    volumesOwned: volumes,
                    readingVolume: currentReadingVolume,
                    completeCollection: hasCompleteCollection
                )
            } catch {
                print("Error al guardar en cloud: \(error)")
                #if os(iOS)
                HapticFeedback.error.trigger()
                #endif
                isSaving = false
                return
            }
        }

        #if os(iOS)
        HapticFeedback.success.trigger()
        #endif
        isSaving = false
        showSuccess = true
    }
}

#Preview(traits: .sampleData) {
    AddToCollectionView(manga: .test)
}
