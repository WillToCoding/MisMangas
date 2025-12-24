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
    @State private var hasCompleteCollection = false
    @State private var showSuccess = false
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Manga") {
                    HStack {
                        AsyncImage(url: URL(string: manga.mainPicture.replacingOccurrences(of: "\"", with: ""))) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 60, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

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
                }

                Section("section_collection") {
                    Toggle("add_complete_collection", isOn: $hasCompleteCollection)
                        .onChange(of: hasCompleteCollection) { _, newValue in
                            if newValue, let totalVolumes = manga.volumes {
                                selectedVolumes = Set(1...totalVolumes)
                            }
                        }
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
                        }
                    }
                }

                if !selectedVolumes.isEmpty {
                    Section("section_reading_progress") {
                        Stepper("vol_current \(currentReadingVolume)", value: $currentReadingVolume, in: 1...(manga.volumes ?? 100))
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

        // Siempre guardar en local (SwiftData)
        let userManga = Model(
            from: manga,
            volumesOwned: volumes,
            readingVolume: currentReadingVolume,
            hasComplete: hasCompleteCollection
        )
        modelContext.insert(userManga)
        try? modelContext.save()

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
            }
        }

        isSaving = false
        showSuccess = true
    }
}

#Preview {
    let authVM = AuthViewModel()
    let cloudVM = CloudCollectionViewModel(authVM: authVM)
    return AddToCollectionView(manga: .test)
        .environment(authVM)
        .environment(cloudVM)
        .modelContainer(.preview)
}
