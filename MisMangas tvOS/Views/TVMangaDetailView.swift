//
//  TVMangaDetailView.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct TVMangaDetailView: View {
    let item: UserMangaCollection
    let onSave: () -> Void

    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.dismiss) private var dismiss

    @State private var currentVolume: Int
    @State private var isSaving = false
    @FocusState private var focusedButton: FocusButton?

    enum FocusButton {
        case decrease, increase, save
    }

    init(item: UserMangaCollection, onSave: @escaping () -> Void = {}) {
        self.item = item
        self.onSave = onSave
        _currentVolume = State(initialValue: item.readingVolume ?? 1)
    }

    var updatedItem: UserMangaCollection {
        cloudVM.cloudCollection.first(where: { $0.id == item.id }) ?? item
    }

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 100) {
                // Portada grande
                AsyncImage(url: URL(string: updatedItem.manga.mainPicture.replacingOccurrences(of: "\"", with: ""))) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 500, height: 750)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .shadow(radius: 40)

                // Información y controles
                VStack(alignment: .leading, spacing: 50) {
                    Text(updatedItem.manga.title)
                        .font(.system(size: 64, weight: .bold))
                        .lineLimit(3)

                    // Stats
                    HStack(spacing: 80) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("detail_score")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.system(size: 36))
                                Text(String(format: "%.2f", updatedItem.manga.score))
                                    .font(.system(size: 52, weight: .bold))
                            }
                        }

                        if let volumes = updatedItem.manga.volumes {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("detail_volumes")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.secondary)
                                Text("\(volumes)")
                                    .font(.system(size: 52, weight: .bold))
                            }
                        }
                    }

                    Divider()

                    // Control de progreso
                    VStack(alignment: .leading, spacing: 30) {
                        Text("edit_progress_section")
                            .font(.system(size: 48, weight: .bold))

                        HStack(spacing: 40) {
                            Button {
                                if currentVolume > 1 {
                                    currentVolume -= 1
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 60))
                            }
                            .disabled(currentVolume <= 1)
                            .focused($focusedButton, equals: .decrease)

                            Text("edit_volume_format \(currentVolume)")
                                .font(.system(size: 52, weight: .bold))
                                .frame(minWidth: 400)

                            Button {
                                if let max = updatedItem.manga.volumes, currentVolume < max {
                                    currentVolume += 1
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 60))
                            }
                            .disabled(currentVolume >= (updatedItem.manga.volumes ?? 999))
                            .focused($focusedButton, equals: .increase)
                        }

                        if let total = updatedItem.manga.volumes {
                            VStack(alignment: .leading, spacing: 16) {
                                ProgressView(value: Double(currentVolume), total: Double(total))
                                    .scaleEffect(y: 3.0)
                                    .frame(maxWidth: 800)

                                Text("progress_percent \(Int((Double(currentVolume) / Double(total)) * 100))")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.secondary)
                            }
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
                                .font(.system(size: 36, weight: .semibold))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isSaving || currentVolume == updatedItem.readingVolume)
                    .focused($focusedButton, equals: .save)
                }
                .frame(maxWidth: 900)
            }
            .padding(120)
        }
        .navigationTitle(updatedItem.manga.title)
        .onAppear {
            focusedButton = .increase
        }
    }

    private func saveProgress() async {
        isSaving = true

        do {
            print("[TV] Guardando progreso: Vol. \(currentVolume) para \(updatedItem.manga.title)")

            try await cloudVM.addToCollection(
                manga: updatedItem.manga,
                volumesOwned: updatedItem.volumesOwned,
                readingVolume: currentVolume,
                completeCollection: updatedItem.completeCollection
            )

            print("[TV] Progreso guardado exitosamente")

            // Notificar PRIMERO a la vista padre
            onSave()

            // Esperar un poco para que SwiftUI procese el cambio
            try? await Task.sleep(for: .milliseconds(150))

            // LUEGO cerrar vista
            dismiss()

            // Esperar otro frame para asegurar que la vista de colección se actualice
            try? await Task.sleep(for: .milliseconds(100))
        } catch {
            print("[TV] ERROR guardando progreso: \(error)")
        }

        isSaving = false
    }
}
