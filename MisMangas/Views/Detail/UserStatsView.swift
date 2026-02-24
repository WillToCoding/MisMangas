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

// MARK: - Editable Stat Card
private struct EditableStatCard: View {
    let value: String
    let label: LocalizedStringKey
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Text(value)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 2) {
                    Text(label)
                    Image(systemName: "pencil")
                        .font(.system(size: 8))
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Editor Sheet
private struct StatusEditorSheet: View {
    let collection: UserCollection
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @State private var selectedStatus: ReadingStatus

    init(collection: UserCollection) {
        self.collection = collection
        _selectedStatus = State(initialValue: collection.readingStatus)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(ReadingStatus.allCases, id: \.self) { status in
                    Button {
                        selectedStatus = status
                    } label: {
                        HStack {
                            Image(systemName: status.icon)
                                .foregroundStyle(status.color)
                                .frame(width: 30)

                            Text(status.localizedName)
                                .foregroundStyle(.primary)

                            Spacer()

                            if selectedStatus == status {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("edit_reading_status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action_cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("action_save") {
                        saveStatus()
                    }
                    .disabled(selectedStatus == collection.readingStatus)
                }
            }
        }
    }

    private func saveStatus() {
        Task {
            // Guardar en local
            let dataContainer = DataContainer(modelContainer: modelContext.container)
            try? await dataContainer.updateUserStats(mangaId: collection.id, readingStatus: selectedStatus)

            // Sincronizar con cloud si está autenticado
            if authVM.isAuthenticated {
                try? await cloudVM.addToCollection(
                    manga: collection.manga.toManga(),
                    volumesOwned: collection.volumesOwned,
                    readingVolume: collection.currentReadingVolume,
                    completeCollection: collection.hasCompleteCollection
                )
                // Marcar como sincronizado para evitar conflictos falsos
                try? await dataContainer.markAsSynced(mangaId: collection.id)
            }

            dismiss()
        }
    }
}

// MARK: - Volume Editor Sheet
private struct VolumeEditorSheet: View {
    let manga: Manga
    let collection: UserCollection
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @State private var selectedVolumes: Set<Int>
    @State private var currentVolume: Int
    @State private var showCloudConflict = false
    @State private var cloudReadingVolume: Int?

    /// Valor inicial al abrir el editor (para detectar conflictos)
    private let initialReadingVolume: Int?

    init(manga: Manga, collection: UserCollection) {
        self.manga = manga
        self.collection = collection
        self.initialReadingVolume = collection.currentReadingVolume
        _selectedVolumes = State(initialValue: Set(collection.volumesOwned))
        _currentVolume = State(initialValue: collection.currentReadingVolume ?? 1)
    }

    private var totalVolumes: Int {
        manga.volumes ?? 50
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("edit_volumes_owned") {
                    if totalVolumes <= 30 {
                        // Grid para pocos volúmenes
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                            ForEach(1...totalVolumes, id: \.self) { vol in
                                VolumeChip(
                                    number: vol,
                                    isSelected: selectedVolumes.contains(vol)
                                ) {
                                    if selectedVolumes.contains(vol) {
                                        selectedVolumes.remove(vol)
                                    } else {
                                        selectedVolumes.insert(vol)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    } else {
                        // Stepper para muchos volúmenes
                        Stepper("volumes_owned_count \(selectedVolumes.count)", value: Binding(
                            get: { selectedVolumes.count },
                            set: { newCount in
                                if newCount > selectedVolumes.count {
                                    for i in 1...totalVolumes where !selectedVolumes.contains(i) && selectedVolumes.count < newCount {
                                        selectedVolumes.insert(i)
                                    }
                                } else {
                                    while selectedVolumes.count > newCount, let last = selectedVolumes.max() {
                                        selectedVolumes.remove(last)
                                    }
                                }
                            }
                        ), in: 0...totalVolumes)
                    }

                    Button(selectedVolumes.count == totalVolumes ? "action_deselect_all" : "action_select_all") {
                        if selectedVolumes.count == totalVolumes {
                            selectedVolumes.removeAll()
                        } else {
                            selectedVolumes = Set(1...totalVolumes)
                        }
                    }
                }

                Section("edit_reading_volume") {
                    Stepper("vol_current \(currentVolume)", value: $currentVolume, in: 1...totalVolumes)
                }
            }
            .navigationTitle("edit_volumes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action_cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("action_save") {
                        saveVolumes()
                    }
                }
            }
            .alert("sync_conflict_title", isPresented: $showCloudConflict) {
                Button("sync_keep_local") {
                    // Guardar valor local (currentVolume) ignorando cloud
                    Task { await performSave() }
                }
                Button("sync_use_cloud") {
                    // Usar valor de cloud y cerrar
                    if let cloudReading = cloudReadingVolume {
                        currentVolume = cloudReading
                    }
                    Task { await performSave() }
                }
                Button("action_cancel", role: .cancel) { }
            } message: {
                if let cloudReading = cloudReadingVolume {
                    Text("sync_conflict_volume_message \(initialReadingVolume ?? 0) \(currentVolume) \(cloudReading)")
                }
            }
        }
    }

    private func saveVolumes() {
        Task {
            // Verificar si cloud tiene un valor diferente al que empezamos a editar
            if authVM.isAuthenticated {
                if let cloudItem = cloudVM.getMangaCollection(manga.id) {
                    let cloudReading = cloudItem.readingVolume
                    // Si cloud cambió desde que abrimos el editor, hay conflicto
                    if cloudReading != initialReadingVolume {
                        cloudReadingVolume = cloudReading
                        showCloudConflict = true
                        return
                    }
                }
            }

            await performSave()
        }
    }

    private func performSave() async {
        let dataContainer = DataContainer(modelContainer: modelContext.container)

        var newStatus: ReadingStatus? = nil
        let hasAllVolumes = selectedVolumes.count == totalVolumes
        let isAtLastVolume = currentVolume == totalVolumes

        if hasAllVolumes && isAtLastVolume {
            newStatus = .completed
        } else if collection.readingStatus == .completed && !isAtLastVolume {
            newStatus = .reading
        } else if collection.readingStatus == .planToRead && currentVolume > 1 {
            newStatus = .reading
        }

        // Guardar en local
        try? await dataContainer.updateUserStats(
            mangaId: collection.id,
            readingStatus: newStatus,
            currentVolume: currentVolume,
            volumesOwned: Array(selectedVolumes).sorted()
        )

        // Sincronizar con cloud si está autenticado
        if authVM.isAuthenticated {
            try? await cloudVM.addToCollection(
                manga: manga,
                volumesOwned: Array(selectedVolumes).sorted(),
                readingVolume: currentVolume,
                completeCollection: hasAllVolumes
            )
            // Marcar como sincronizado para evitar conflictos falsos
            try? await dataContainer.markAsSynced(mangaId: collection.id)
        }

        dismiss()
    }
}

// MARK: - Volume Chip
private struct VolumeChip: View {
    let number: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(number)")
                .font(.caption.bold())
                .frame(width: 36, height: 36)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview(traits: .sampleData) {
    ScrollView {
        UserStatsView(manga: .test, collection: PreviewData.shared.sampleCollection)
            .padding()
    }
}
