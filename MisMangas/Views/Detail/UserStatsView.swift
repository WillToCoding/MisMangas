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
    @State private var showScoreEditor = false
    @State private var showVolumeEditor = false
    @State private var showChapterEditor = false
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

            // Fila 1: Mi Score + Mi Estado
            HStack(spacing: 12) {
                // Score del usuario (editable)
                EditableStatCard(
                    value: collection.userScore.map { String(format: "%.1f", $0) } ?? "-",
                    label: "detail_my_score",
                    icon: "star.circle.fill",
                    color: .yellow
                ) {
                    showScoreEditor = true
                }

                // Status del usuario (editable)
                EditableStatCard(
                    value: collection.readingStatus.localizedName,
                    label: "detail_my_status",
                    icon: collection.readingStatus.icon,
                    color: collection.readingStatus.color
                ) {
                    showStatusEditor = true
                }
            }

            // Fila 2: Mis Volúmenes + Mi Capítulo
            HStack(spacing: 12) {
                // Volúmenes (editable)
                EditableStatCard(
                    value: volumeText,
                    label: "detail_my_volumes",
                    icon: "books.vertical.fill",
                    color: .blue
                ) {
                    showVolumeEditor = true
                }

                // Capítulos (editable)
                EditableStatCard(
                    value: chapterText,
                    label: "detail_my_chapter",
                    icon: "book.pages.fill",
                    color: .purple
                ) {
                    showChapterEditor = true
                }
            }
        }
        .sheet(isPresented: $showScoreEditor) {
            ScoreEditorSheet(collection: collection)
                .presentationDetents([.height(280)])
        }
        .sheet(isPresented: $showStatusEditor) {
            StatusEditorSheet(collection: collection)
                .presentationDetents([.height(350)])
        }
        .sheet(isPresented: $showVolumeEditor) {
            VolumeEditorSheet(manga: manga, collection: collection)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showChapterEditor) {
            ChapterEditorSheet(manga: manga, collection: collection)
                .presentationDetents([.height(280)])
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

    private var chapterText: String {
        let current = collection.currentChapter ?? 0
        if let total = manga.chapters {
            return "\(current)/\(total)"
        } else {
            return "\(current)"
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

// MARK: - Score Editor Sheet
private struct ScoreEditorSheet: View {
    let collection: UserCollection
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var score: Double

    init(collection: UserCollection) {
        self.collection = collection
        _score = State(initialValue: collection.userScore ?? 7.0)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(String(format: "%.1f", score))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.yellow)

                HStack {
                    Image(systemName: "star")
                    Slider(value: $score, in: 1...10, step: 0.5)
                    Image(systemName: "star.fill")
                }
                .padding(.horizontal)

                if collection.userScore == nil {
                    Text("edit_score_hint")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("edit_my_score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action_cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("action_save") {
                        saveScore()
                    }
                }
            }
        }
    }

    private func saveScore() {
        Task {
            let dataContainer = DataContainer(modelContainer: modelContext.container)
            try? await dataContainer.updateUserStats(mangaId: collection.id, userScore: score)
            dismiss()
        }
    }
}

// MARK: - Status Editor Sheet
private struct StatusEditorSheet: View {
    let collection: UserCollection
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
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
            let dataContainer = DataContainer(modelContainer: modelContext.container)
            try? await dataContainer.updateUserStats(mangaId: collection.id, readingStatus: selectedStatus)
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
    @State private var selectedVolumes: Set<Int>
    @State private var currentVolume: Int

    init(manga: Manga, collection: UserCollection) {
        self.manga = manga
        self.collection = collection
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
        }
    }

    private func saveVolumes() {
        Task {
            let dataContainer = DataContainer(modelContainer: modelContext.container)
            try? await dataContainer.updateUserStats(
                mangaId: collection.id,
                currentVolume: currentVolume,
                volumesOwned: Array(selectedVolumes).sorted()
            )
            dismiss()
        }
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

// MARK: - Chapter Editor Sheet
private struct ChapterEditorSheet: View {
    let manga: Manga
    let collection: UserCollection
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var currentChapter: Int

    init(manga: Manga, collection: UserCollection) {
        self.manga = manga
        self.collection = collection
        _currentChapter = State(initialValue: collection.currentChapter ?? 1)
    }

    private var totalChapters: Int {
        manga.chapters ?? 9999
    }

    private var useSlider: Bool {
        totalChapters > 20
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("\(currentChapter)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.purple)

                if let total = manga.chapters {
                    Text("edit_of_total \(total)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ProgressView(value: Double(currentChapter), total: Double(total))
                        .tint(.purple)
                        .padding(.horizontal)
                }

                // Slider para muchos capítulos, Stepper para pocos
                if useSlider {
                    VStack(spacing: 8) {
                        Slider(
                            value: Binding(
                                get: { Double(currentChapter) },
                                set: { currentChapter = Int($0) }
                            ),
                            in: 0...Double(totalChapters),
                            step: 1
                        )
                        .tint(.purple)

                        // Botones de ajuste fino
                        HStack {
                            Button {
                                if currentChapter > 0 { currentChapter -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                            }
                            .disabled(currentChapter <= 0)

                            Spacer()

                            Text("chapter_current \(currentChapter)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button {
                                if currentChapter < totalChapters { currentChapter += 1 }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                            .disabled(currentChapter >= totalChapters)
                        }
                        .foregroundStyle(.purple)
                    }
                    .padding(.horizontal)
                } else {
                    Stepper("chapter_current \(currentChapter)", value: $currentChapter, in: 0...totalChapters)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("edit_chapter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action_cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("action_save") {
                        saveChapter()
                    }
                }
            }
        }
    }

    private func saveChapter() {
        Task {
            let dataContainer = DataContainer(modelContainer: modelContext.container)
            try? await dataContainer.updateUserStats(mangaId: collection.id, currentChapter: currentChapter)
            dismiss()
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
