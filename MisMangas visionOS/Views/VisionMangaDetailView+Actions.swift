//
//  VisionMangaDetailView+Actions.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 26/02/26.
//

import SwiftUI

// MARK: - Translation

extension VisionMangaDetailView {
    func translationButton(synopsis: String) -> some View {
        Group {
            if translationService.isConfigured {
                if isTranslating {
                    ProgressView()
                } else if translatedSynopsis != nil {
                    Button {
                        showOriginal.toggle()
                    } label: {
                        Label(
                            showOriginal ? "translation_show_translated" : "translation_show_original",
                            systemImage: "globe"
                        )
                        .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        Task { await translateSynopsis(synopsis) }
                    } label: {
                        Label("translation_translate", systemImage: "globe")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    func translateSynopsis(_ synopsis: String) async {
        isTranslating = true
        let targetLanguage = Locale.current.language.languageCode?.identifier ?? "es"

        do {
            translatedSynopsis = try await translationService.translate(synopsis, to: targetLanguage)
        } catch {
            print("[VISION] Error traduciendo: \(error)")
        }

        isTranslating = false
    }
}

// MARK: - Save & Delete Actions

extension VisionMangaDetailView {
    func saveProgress() async {
        isSaving = true
        showSuccess = false

        do {
            let newVolumesOwned = ownedVolumes > 0 ? Array(1...ownedVolumes) : []
            try await onSave(currentVolume, newVolumesOwned, isCompleted)
            showSuccess = true
            try? await Task.sleep(for: .milliseconds(500))
            dismiss()
        } catch {
            print("[VISION] Error guardando: \(error)")
        }

        isSaving = false
    }

    func deleteManga() async {
        isDeleting = true

        do {
            try await onDelete()
            dismiss()
        } catch {
            print("[VISION] Error eliminando: \(error)")
        }

        isDeleting = false
    }
}
