//
//  VisionMangaDetailView.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct VisionMangaDetailView: View {
    let item: UserMangaCollection
    let onSave: () -> Void

    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.dismiss) private var dismiss

    @State private var currentVolume: Int
    @State private var isSaving = false
    @State private var showSuccess = false

    init(item: UserMangaCollection, onSave: @escaping () -> Void = {}) {
        self.item = item
        self.onSave = onSave
        _currentVolume = State(initialValue: item.readingVolume ?? 1)
    }

    var updatedItem: UserMangaCollection {
        cloudVM.cloudCollection.first(where: { $0.id == item.id }) ?? item
    }

    var hasChanges: Bool {
        currentVolume != updatedItem.readingVolume
    }

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 60) {
                // Portada grande
                AsyncImage(url: URL(string: updatedItem.manga.mainPicture.replacingOccurrences(of: "\"", with: ""))) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 400, height: 600)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 30)

                // Información
                VStack(alignment: .leading, spacing: 30) {
                    Text(updatedItem.manga.title)
                        .font(.system(size: 48, weight: .bold))

                    HStack(spacing: 40) {
                        VStack(alignment: .leading) {
                            Text("detail_score")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text(String(format: "%.2f", updatedItem.manga.score))
                                    .font(.title.bold())
                            }
                        }

                        if let volumes = updatedItem.manga.volumes {
                            VStack(alignment: .leading) {
                                Text("detail_volumes")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(volumes)")
                                    .font(.title.bold())
                            }
                        }
                    }

                    Divider()

                    // Control de progreso
                    VStack(alignment: .leading, spacing: 20) {
                        Text("edit_progress_section")
                            .font(.title2.bold())

                        HStack {
                            Button {
                                if currentVolume > 1 {
                                    currentVolume -= 1
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                            }
                            .disabled(currentVolume <= 1)

                            Text("vol_current \(currentVolume)")
                                .font(.title.bold())
                                .frame(minWidth: 200)

                            Button {
                                if let max = updatedItem.manga.volumes, currentVolume < max {
                                    currentVolume += 1
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                            }
                            .disabled(currentVolume >= (updatedItem.manga.volumes ?? 999))
                        }

                        if let total = updatedItem.manga.volumes {
                            ProgressView(value: Double(currentVolume), total: Double(total))
                                .frame(maxWidth: 400)
                        }
                    }

                    Divider()

                    Button {
                        Task {
                            await saveProgress()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else if showSuccess {
                            Label("action_save", systemImage: "checkmark.circle.fill")
                        } else {
                            Label("action_save", systemImage: "square.and.arrow.up")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isSaving || !hasChanges)
                    .tint(showSuccess ? .green : .accentColor)
                }
                .frame(maxWidth: 600)
            }
            .padding(60)
        }
        .navigationTitle(updatedItem.manga.title)
    }

    private func saveProgress() async {
        isSaving = true
        showSuccess = false

        do {
            print("[VISION] Guardando progreso: Vol. \(currentVolume) para \(updatedItem.manga.title)")

            try await cloudVM.addToCollection(
                manga: updatedItem.manga,
                volumesOwned: updatedItem.volumesOwned,
                readingVolume: currentVolume,
                completeCollection: updatedItem.completeCollection
            )

            print("[VISION] Progreso guardado exitosamente")

            // Notificar PRIMERO a la vista padre
            onSave()

            // Esperar un poco para que SwiftUI procese el cambio
            try? await Task.sleep(for: .milliseconds(150))

            // LUEGO cerrar vista
            dismiss()

            // Esperar otro frame para asegurar que la vista de colección se actualice
            try? await Task.sleep(for: .milliseconds(100))
        } catch {
            print("[VISION] ERROR guardando progreso: \(error)")
        }

        isSaving = false
    }
}
