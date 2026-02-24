//
//  MacCollectionView.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI
import SwiftData

struct MacCollectionView: View {
    @Binding var selection: Manga?

    @Query(sort: \UserCollection.addedDate, order: .reverse) private var localCollection: [UserCollection]
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    @State private var showDeleteAlert = false
    @State private var mangaToDelete: Int?
    @State private var collectionItemToEdit: UserMangaCollection?
    @State private var localItemToEdit: UserCollection?

    private let demographicConfig: [(key: String, title: LocalizedStringKey, icon: String, color: Color)] = [
        ("Shounen", "section_shounen", "flame.fill", .orange),
        ("Seinen", "section_seinen", "person.fill", .purple),
        ("Shoujo", "section_shoujo", "heart.fill", .pink),
        ("Josei", "section_josei", "sparkles", .indigo),
        ("Kids", "section_kids", "star.fill", .yellow)
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                if authVM.isAuthenticated {
                    cloudCollectionContent
                } else {
                    localCollectionContent
                }

                Spacer(minLength: 50)
            }
            .padding(.vertical)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("nav_collection")
        .toolbar {
            ToolbarItem {
                if authVM.isAuthenticated {
                    Image(systemName: "cloud.fill")
                        .foregroundStyle(.blue)
                }
            }

            ToolbarItem {
                Button {
                    Task {
                        if authVM.isAuthenticated {
                            await cloudVM.loadCollection()
                        }
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("action_refresh")
            }
        }
        .task {
            if authVM.isAuthenticated {
                await cloudVM.loadCollection()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshContent)) { _ in
            if authVM.isAuthenticated {
                Task {
                    await cloudVM.loadCollection()
                }
            }
        }
        .alert("collection_delete_title", isPresented: $showDeleteAlert) {
            Button("action_cancel", role: .cancel) { }
            Button("action_delete", role: .destructive) {
                if let mangaId = mangaToDelete {
                    Task {
                        try? await cloudVM.removeFromCollection(mangaId: mangaId)
                    }
                }
            }
        } message: {
            Text("collection_delete_message")
        }
        .sheet(item: $collectionItemToEdit) { item in
            MacEditCollectionView(collectionItem: item)
        }
        .sheet(item: $localItemToEdit) { item in
            MacEditLocalCollectionView(collection: item)
        }
        .overlay {
            if cloudVM.state.isLoading {
                ProgressView("loading_collection")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Cloud Collection Content

    @ViewBuilder
    private var cloudCollectionContent: some View {
        if cloudVM.cloudCollection.isEmpty && !cloudVM.state.isLoading {
            emptyStateView
        } else {
            // Agrupar por demografía
            ForEach(demographicConfig, id: \.key) { config in
                let mangas = cloudVM.cloudCollection.filter { item in
                    item.manga.demographics.contains { $0.demographic == config.key }
                }
                if !mangas.isEmpty {
                    collectionSection(
                        title: config.title,
                        icon: config.icon,
                        color: config.color,
                        items: mangas
                    )
                }
            }

            // Mangas sin demografía
            let otherMangas = cloudVM.cloudCollection.filter { item in
                item.manga.demographics.isEmpty
            }
            if !otherMangas.isEmpty {
                collectionSection(
                    title: "section_other",
                    icon: "square.grid.2x2",
                    color: .gray,
                    items: otherMangas
                )
            }
        }
    }

    // MARK: - Local Collection Content

    @ViewBuilder
    private var localCollectionContent: some View {
        if localCollection.isEmpty {
            emptyStateView
        } else {
            // Agrupar por demografía
            ForEach(demographicConfig, id: \.key) { config in
                let items = localCollection.filter { item in
                    item.manga.demographicNames.contains(config.key)
                }
                if !items.isEmpty {
                    localCollectionSection(
                        title: config.title,
                        icon: config.icon,
                        color: config.color,
                        items: items
                    )
                }
            }

            // Mangas sin demografía
            let otherItems = localCollection.filter { item in
                item.manga.demographicNames.isEmpty
            }
            if !otherItems.isEmpty {
                localCollectionSection(
                    title: "section_other",
                    icon: "square.grid.2x2",
                    color: .gray,
                    items: otherItems
                )
            }
        }
    }

    // MARK: - Collection Section (Cloud)

    private func collectionSection(
        title: LocalizedStringKey,
        icon: String,
        color: Color,
        items: [UserMangaCollection]
    ) -> some View {
        MacHorizontalSection(
            title: title,
            icon: icon,
            color: color,
            itemCount: items.count
        ) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                MacCollectionCard(manga: item.manga, item: item)
                    .id(index)
                    .onTapGesture {
                        selection = item.manga
                    }
                    .contextMenu {
                        Button {
                            collectionItemToEdit = item
                        } label: {
                            Label("action_edit", systemImage: "pencil")
                        }

                        Divider()

                        Button("action_delete", role: .destructive) {
                            mangaToDelete = item.manga.id
                            showDeleteAlert = true
                        }
                    }
            }
        }
    }

    // MARK: - Local Collection Section

    private func localCollectionSection(
        title: LocalizedStringKey,
        icon: String,
        color: Color,
        items: [UserCollection]
    ) -> some View {
        MacHorizontalSection(
            title: title,
            icon: icon,
            color: color,
            itemCount: items.count
        ) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                MacLocalCollectionCard(collection: item)
                    .id(index)
                    .onTapGesture {
                        selection = item.manga.toManga()
                    }
                    .contextMenu {
                        Button {
                            localItemToEdit = item
                        } label: {
                            Label("action_edit", systemImage: "pencil")
                        }

                        Divider()

                        Button("action_delete", role: .destructive) {
                            Task {
                                let dataContainer = DataContainer(modelContainer: modelContext.container)
                                try? await dataContainer.removeFromCollection(mangaId: item.manga.id)
                            }
                        }
                    }
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "collection_empty_title",
            systemImage: "books.vertical",
            description: Text("collection_empty_description")
        )
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

// MARK: - Collection Card (Cloud)

struct MacCollectionCard: View {
    let manga: Manga
    let item: UserMangaCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                CachedCoverImage(
                    url: manga.coverURL,
                    width: 120,
                    height: 180,
                    cornerRadius: 12
                )

                // Badge de progreso
                if item.completeCollection {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                        .background(Circle().fill(.white).padding(2))
                        .padding(8)
                } else if let reading = item.readingVolume, let total = manga.volumes {
                    Text("\(reading)/\(total)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.blue, in: Capsule())
                        .padding(8)
                }

                // Score
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.yellow)
                            Text(manga.score.formatted(.number.precision(.fractionLength(1))))
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.6), in: Capsule())
                        .padding(6)
                    }
                }
                .frame(width: 120, height: 180)
            }

            Text(manga.title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 120, height: 36, alignment: .top)
                .padding(.top, 8)
        }
        .frame(width: 120)
    }
}

// MARK: - Local Collection Card

struct MacLocalCollectionCard: View {
    let collection: UserCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                CachedCoverImage(
                    url: collection.collectionCoverURL,
                    width: 120,
                    height: 180,
                    cornerRadius: 12
                )

                // Badge de progreso
                if collection.hasCompleteCollection {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                        .background(Circle().fill(.white).padding(2))
                        .padding(8)
                } else if let reading = collection.currentReadingVolume, let total = collection.totalVolumes {
                    Text("\(reading)/\(total)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.blue, in: Capsule())
                        .padding(8)
                }

                // Score
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.yellow)
                            Text(collection.score.formatted(.number.precision(.fractionLength(1))))
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.6), in: Capsule())
                        .padding(6)
                    }
                }
                .frame(width: 120, height: 180)
            }

            Text(collection.title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 120, height: 36, alignment: .top)
                .padding(.top, 8)
        }
        .frame(width: 120)
    }
}

// MARK: - Edit Cloud Collection View
struct MacEditCollectionView: View {
    let collectionItem: UserMangaCollection

    @Environment(\.dismiss) private var dismiss
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    @State private var volumesOwnedCount: Double
    @State private var currentReadingVolume: Double
    @State private var isSaving = false
    @State private var showCloudConflict = false
    @State private var cloudReadingVolume: Int?

    /// Valor inicial al abrir el editor (para detectar conflictos)
    private let initialReadingVolume: Int?

    private var totalVolumes: Int {
        collectionItem.manga.volumes ?? 50
    }

    init(collectionItem: UserMangaCollection) {
        self.collectionItem = collectionItem
        self.initialReadingVolume = collectionItem.readingVolume
        _volumesOwnedCount = State(initialValue: Double(collectionItem.volumesOwned.count))
        _currentReadingVolume = State(initialValue: Double(collectionItem.readingVolume ?? 1))
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack(spacing: 16) {
                CachedCoverImage(
                    url: collectionItem.manga.coverURL,
                    width: 80,
                    height: 120
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(collectionItem.manga.title)
                        .font(.title2.bold())
                        .lineLimit(2)

                    if let total = collectionItem.manga.volumes {
                        Text("\(total) volumes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal)

            Divider()

            // Info de volumenes
            if collectionItem.manga.volumes == nil {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.orange)
                    Text("edit_ongoing_manga")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }

            // Sliders
            VStack(spacing: 32) {
                // Volumenes en propiedad
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("edit_volumes_owned", systemImage: "books.vertical.fill")
                            .font(.headline)
                        Spacer()

                        HStack(spacing: 4) {
                            TextField("", value: $volumesOwnedCount, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                                .multilineTextAlignment(.center)

                            if let total = collectionItem.manga.volumes {
                                Text("/ \(total)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.title3.bold().monospacedDigit())
                    }

                    Slider(value: $volumesOwnedCount, in: 0...Double(totalVolumes), step: 1)
                        .tint(.blue)
                }

                // Volumen de lectura actual
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("edit_reading_volume", systemImage: "bookmark.fill")
                            .font(.headline)
                        Spacer()

                        TextField("", value: $currentReadingVolume, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .multilineTextAlignment(.center)
                            .font(.title3.bold().monospacedDigit())
                    }

                    Slider(value: $currentReadingVolume, in: 1...max(1, Double(totalVolumes), volumesOwnedCount), step: 1)
                        .tint(.orange)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Botones
            HStack(spacing: 16) {
                Button("action_cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.bordered)

                Button("action_save") {
                    Task {
                        await saveChanges()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
            }
            .padding()
        }
        .padding(.vertical)
        .frame(width: 450, height: 420)
        .alert("sync_conflict_title", isPresented: $showCloudConflict) {
            Button("sync_keep_local") {
                Task { await performSave() }
            }
            Button("sync_use_cloud") {
                if let cloudReading = cloudReadingVolume {
                    currentReadingVolume = Double(cloudReading)
                }
                Task { await performSave() }
            }
            Button("action_cancel", role: .cancel) { }
        } message: {
            if let cloudReading = cloudReadingVolume {
                Text("sync_conflict_volume_message \(initialReadingVolume ?? 0) \(Int(currentReadingVolume)) \(cloudReading)")
            }
        }
    }

    private func saveChanges() async {
        // Refrescar de cloud para obtener el valor actual
        await cloudVM.loadCollection()

        // Verificar si cloud tiene un valor diferente al que empezamos a editar
        if let cloudItem = cloudVM.getMangaCollection(collectionItem.manga.id) {
            let cloudReading = cloudItem.readingVolume
            print("[MAC DEBUG] initialReadingVolume: \(String(describing: initialReadingVolume))")
            print("[MAC DEBUG] cloudReading: \(String(describing: cloudReading))")
            print("[MAC DEBUG] Son diferentes: \(cloudReading != initialReadingVolume)")

            if cloudReading != initialReadingVolume {
                cloudReadingVolume = cloudReading
                showCloudConflict = true
                print("[MAC DEBUG] Mostrando alerta de conflicto")
                return
            }
        } else {
            print("[MAC DEBUG] No se encontró el item en cloud")
        }

        await performSave()
    }

    private func performSave() async {
        isSaving = true

        let ownedCount = Int(volumesOwnedCount)
        let volumes = ownedCount > 0 ? Array(1...ownedCount) : []
        let readingVol = Int(currentReadingVolume)
        let isComplete = ownedCount == totalVolumes

        do {
            try await cloudVM.addToCollection(
                manga: collectionItem.manga,
                volumesOwned: volumes,
                readingVolume: readingVol,
                completeCollection: isComplete
            )
            print("Guardado en cloud: \(collectionItem.manga.title)")
        } catch {
            print("Error guardando en cloud: \(error)")
        }

        isSaving = false
        dismiss()
    }
}

// MARK: - Edit Local Collection View
struct MacEditLocalCollectionView: View {
    @Bindable var collection: UserCollection

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedVolumes: Set<Int>
    @State private var currentReadingVolume: Int
    @State private var hasCompleteCollection: Bool

    init(collection: UserCollection) {
        self.collection = collection
        _selectedVolumes = State(initialValue: Set(collection.volumesOwned))
        _currentReadingVolume = State(initialValue: collection.currentReadingVolume ?? 1)
        _hasCompleteCollection = State(initialValue: collection.hasCompleteCollection)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("action_edit")
                .font(.title.bold())

            CachedCoverImage(
                url: collection.collectionCoverURL,
                width: 150,
                height: 225
            )

            Text(collection.title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Form {
                Toggle("add_complete_collection", isOn: $hasCompleteCollection)
                    .onChange(of: hasCompleteCollection) { _, newValue in
                        if newValue, let totalVolumes = collection.totalVolumes {
                            selectedVolumes = Set(1...totalVolumes)
                        }
                    }

                if !hasCompleteCollection {
                    HStack {
                        Text("detail_volumes")
                        TextField("1,2,3", text: Binding(
                            get: {
                                selectedVolumes.sorted().map(String.init).joined(separator: ",")
                            },
                            set: { text in
                                let volumes = text.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                                selectedVolumes = Set(volumes)
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }

                Stepper("collection_reading_volume \(currentReadingVolume)", value: $currentReadingVolume, in: 1...(collection.totalVolumes ?? 100))
            }
            .padding()

            Spacer()

            HStack {
                Button("action_cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("action_save") {
                    saveChanges()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .padding()
        .frame(width: 500, height: 600)
    }

    private func saveChanges() {
        Task {
            let dataContainer = DataContainer(modelContainer: modelContext.container)
            do {
                try await dataContainer.updateUserStats(
                    mangaId: collection.manga.id,
                    currentVolume: currentReadingVolume,
                    volumesOwned: Array(selectedVolumes).sorted(),
                    hasCompleteCollection: hasCompleteCollection
                )
            } catch {
                print("Error guardando cambios: \(error)")
            }
            dismiss()
        }
    }
}

#Preview(traits: .sampleData) {
    @Previewable @State var selection: Manga? = nil
    MacCollectionView(selection: $selection)
}
