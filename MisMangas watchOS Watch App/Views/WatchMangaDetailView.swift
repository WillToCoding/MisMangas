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
    @State private var isSaving = false

    init(item: UserMangaCollection, onSave: @escaping () -> Void = {}) {
        self.item = item
        self.onSave = onSave
        _currentVolume = State(initialValue: item.readingVolume ?? 0)
    }

    // Obtener el item actualizado de la colección actual
    private var updatedItem: UserMangaCollection {
        cloudVM.cloudCollection.first(where: { $0.id == item.id }) ?? item
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Título
                Text(updatedItem.manga.title)
                    .font(.headline)

                // Puntuación
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(updatedItem.manga.score.formatted(.number.precision(.fractionLength(2))))
                }
                .font(.caption)

                Divider()

                // Volumen actual
                VStack(alignment: .leading, spacing: 8) {
                    Text("add_reading_volume")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Stepper(
                        value: $currentVolume,
                        in: 0...(updatedItem.manga.volumes ?? 999)
                    ) {
                        Text("vol_current \(currentVolume)")
                            .font(.title3.bold())
                    }
                }

                // Progress
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

                Divider()

                // Botón guardar
                Button {
                    Task {
                        await saveProgress()
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Label("action_save", systemImage: "checkmark.circle.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving || currentVolume == updatedItem.readingVolume)
            }
            .padding()
        }
        .navigationTitle("nav_detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveProgress() async {
        isSaving = true

        do {
            print("[WATCH] Guardando progreso: Vol. \(currentVolume) para \(updatedItem.manga.title)")

            try await cloudVM.addToCollection(
                manga: updatedItem.manga,
                volumesOwned: updatedItem.volumesOwned,
                readingVolume: currentVolume,
                completeCollection: updatedItem.completeCollection
            )

            // Pequeña vibración de éxito
            WKInterfaceDevice.current().play(.success)

            print("[WATCH] Progreso guardado exitosamente")
            print("[WATCH] Coleccion actualizada: \(cloudVM.cloudCollection.count) items")

            // Verificar que el cambio se guardó
            if let updatedFromCollection = cloudVM.cloudCollection.first(where: { $0.id == item.id }) {
                print("[WATCH] Verificacion: readingVolume ahora es \(updatedFromCollection.readingVolume ?? -1)")
            }

            // Notificar PRIMERO a la vista padre
            onSave()

            // Esperar un poco para que SwiftUI procese el cambio
            try? await Task.sleep(for: .milliseconds(150))

            // LUEGO cerrar vista
            dismiss()

            // Esperar otro frame para asegurar que la vista de colección se actualice
            try? await Task.sleep(for: .milliseconds(100))
        } catch {
            print("[WATCH] ERROR guardando progreso: \(error)")
            WKInterfaceDevice.current().play(.failure)
        }

        isSaving = false
    }
}
