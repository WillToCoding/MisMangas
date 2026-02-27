//
//  VisionAddToCollectionSheet.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 26/02/26.
//

import SwiftUI
import SwiftData

struct VisionAddToCollectionSheet: View {
    let manga: Manga
    let onAdded: () -> Void

    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var volumesOwned: [Int] = []
    @State private var currentVolume: Int = 1
    @State private var completeCollection = false
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("edit_progress_section") {
                    Stepper("vol_current \(currentVolume)", value: $currentVolume, in: 1...(manga.volumes ?? 100))
                }

                Section {
                    Toggle("collection_complete", isOn: $completeCollection)
                        .onChange(of: completeCollection) { _, isComplete in
                            if isComplete, let total = manga.volumes {
                                volumesOwned = Array(1...total)
                            }
                        }
                }

                if let total = manga.volumes {
                    Section("collection_volumes_owned") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 10) {
                            ForEach(1...total, id: \.self) { vol in
                                Button {
                                    if volumesOwned.contains(vol) {
                                        volumesOwned.removeAll { $0 == vol }
                                    } else {
                                        volumesOwned.append(vol)
                                    }
                                } label: {
                                    Text("\(vol)")
                                        .frame(width: 44, height: 44)
                                        .background(volumesOwned.contains(vol) ? Color.accentColor : Color.gray.opacity(0.3))
                                        .foregroundStyle(volumesOwned.contains(vol) ? .white : .primary)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle(manga.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action_cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await addToCollection()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("action_add")
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }

    private func addToCollection() async {
        isSaving = true
        let volumes = volumesOwned.sorted()

        // Siempre guardar en local
        let dataContainer = DataContainer(modelContainer: modelContext.container)
        do {
            try await dataContainer.addToCollection(
                manga: manga,
                volumesOwned: volumes,
                currentReadingVolume: currentVolume,
                hasCompleteCollection: completeCollection,
                readingStatus: .planToRead
            )
        } catch {
            print("[VISION] Error saving to local: \(error)")
            isSaving = false
            return
        }

        // Si está autenticado, también guardar en cloud
        if authVM.isAuthenticated {
            do {
                try await cloudVM.addToCollection(
                    manga: manga,
                    volumesOwned: volumes,
                    readingVolume: currentVolume,
                    completeCollection: completeCollection
                )
            } catch {
                print("[VISION] Error saving to cloud: \(error)")
                isSaving = false
                return
            }
        }

        onAdded()
        dismiss()
        isSaving = false
    }
}

#Preview {
    VisionAddToCollectionSheet(manga: .test, onAdded: { })
        .environment(AuthViewModel())
        .environment(CloudCollectionViewModel(authVM: AuthViewModel()))
}
