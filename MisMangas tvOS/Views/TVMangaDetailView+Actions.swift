//
//  TVMangaDetailView+Actions.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 25/2/26.
//

import SwiftUI

// MARK: - Actions

extension TVMangaDetailView {

    func translateSynopsis() async {
        guard let synopsis = item.collectionSynopsis else { return }

        isTranslating = true
        let targetLanguage = Locale.current.language.languageCode?.identifier ?? "es"

        do {
            translatedSynopsis = try await translationService.translate(synopsis, to: targetLanguage)
        } catch {
            print("[TV] Error traduciendo: \(error)")
        }

        isTranslating = false
    }

    func saveProgress() async {
        isSaving = true

        let ownedCount = Int(ownedVolumes)
        let newVolumesOwned = ownedCount > 0 ? Array(1...ownedCount) : []
        let justCompleted = Int(currentVolume) == totalVolumes && totalVolumes > 0

        do {
            try await onSave(Int(currentVolume), newVolumesOwned, isCompleted)

            // Haptic feedback: celebración si completó, éxito si solo guardó
            if justCompleted {
                TVHapticFeedback.celebration.trigger()
            } else {
                TVHapticFeedback.success.trigger()
            }

            showSavedConfirmation = true
            try? await Task.sleep(for: .seconds(1.5))
            showSavedConfirmation = false

            await onRefresh()

            try? await Task.sleep(for: .milliseconds(200))
            dismiss()
        } catch {
            TVHapticFeedback.error.trigger()
            print("[TV] Error guardando progreso: \(error)")
        }

        isSaving = false
    }

    func deleteManga() async {
        isDeleting = true

        do {
            try await onDelete()
            await onRefresh()
            dismiss()
        } catch {
            print("[TV] Error eliminando manga: \(error)")
        }

        isDeleting = false
    }
}
