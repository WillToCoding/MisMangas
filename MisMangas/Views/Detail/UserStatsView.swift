//
//  UserStatsView.swift
//  MisMangas
//
//  Created by Juan Carlos on 2/2/26.
//

import SwiftUI
import SwiftData

/// Vista de estadísticas editables para mangas en la colección del usuario
struct UserStatsView: View {
    let manga: Manga
    let collection: UserCollection

    @Environment(\.modelContext) private var modelContext
    @State private var showVolumeEditor = false
    @State private var showStatusEditor = false

    var body: some View {
        VStack(spacing: 12) {
            // Título de sección
            HStack {
                Label("section_my_progress", systemImage: "person.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                Spacer()
            }

            // Fila: Estado + Volúmenes
            HStack(spacing: 12) {
                // Status del usuario (editable)
                EditableStatCard(
                    value: collection.readingStatus.localizedName,
                    label: "detail_my_status",
                    icon: collection.readingStatus.icon,
                    color: collection.readingStatus.color
                ) {
                    showStatusEditor = true
                }

                // Volúmenes (editable)
                EditableStatCard(
                    value: volumeText,
                    label: "detail_my_volumes",
                    icon: "books.vertical.fill",
                    color: .blue
                ) {
                    showVolumeEditor = true
                }
            }
        }
        .sheet(isPresented: $showStatusEditor) {
            StatusEditorSheet(collection: collection)
                .presentationDetents([.height(350)])
        }
        .sheet(isPresented: $showVolumeEditor) {
            VolumeEditorSheet(manga: manga, collection: collection)
                .presentationDetents([.medium])
        }
    }

    private var volumeText: String {
        let owned = collection.volumesOwned.count
        if collection.hasCompleteCollection {
            return String(localized: "stats_complete")
        } else if let total = manga.volumes {
            return "\(owned)/\(total)"
        } else {
            return "\(owned)"
        }
    }
}

// MARK: - Preview

#Preview(traits: .sampleData) {
    ScrollView {
        UserStatsView(manga: .test, collection: PreviewData.shared.sampleCollection)
            .padding()
    }
}
