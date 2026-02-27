//
//  TVCollectionView.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI
import SwiftData

struct TVCollectionView: View {
    @Bindable var cloudVM: CloudCollectionViewModel
    @Query(sort: \UserCollection.addedDate, order: .reverse) private var localCollection: [UserCollection]
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.modelContext) private var modelContext

    // MARK: - Stats computados

    private var totalMangas: Int {
        authVM.isAuthenticated ? cloudVM.cloudCollection.count : localCollection.count
    }

    private var completedMangas: Int {
        if authVM.isAuthenticated {
            return cloudVM.cloudCollection.filter { item in
                guard let total = item.manga.volumes else { return false }
                return item.readingVolume == total
            }.count
        } else {
            return localCollection.filter { item in
                guard let total = item.manga.volumes else { return false }
                return item.currentReadingVolume == total
            }.count
        }
    }

    private var overallProgress: Int {
        if authVM.isAuthenticated {
            let items = cloudVM.cloudCollection.compactMap { item -> (current: Int, total: Int)? in
                guard let total = item.manga.volumes, total > 0 else { return nil }
                return (item.readingVolume ?? 0, total)
            }
            guard !items.isEmpty else { return 0 }
            let totalRead = items.reduce(0) { $0 + $1.current }
            let totalVolumes = items.reduce(0) { $0 + $1.total }
            return totalVolumes > 0 ? Int((Double(totalRead) / Double(totalVolumes)) * 100) : 0
        } else {
            let items = localCollection.compactMap { item -> (current: Int, total: Int)? in
                guard let total = item.manga.volumes, total > 0 else { return nil }
                return (item.currentReadingVolume ?? 0, total)
            }
            guard !items.isEmpty else { return 0 }
            let totalRead = items.reduce(0) { $0 + $1.current }
            let totalVolumes = items.reduce(0) { $0 + $1.total }
            return totalVolumes > 0 ? Int((Double(totalRead) / Double(totalVolumes)) * 100) : 0
        }
    }

    private var isEmpty: Bool {
        authVM.isAuthenticated ? cloudVM.cloudCollection.isEmpty : localCollection.isEmpty
    }

    // MARK: - Body

    var body: some View {
        Group {
            if isEmpty && !cloudVM.state.isLoading {
                ContentUnavailableView(
                    "collection_empty_title",
                    systemImage: "books.vertical",
                    description: Text("collection_empty_description")
                )
            } else {
                collectionContent
            }
        }
        .navigationTitle("nav_collection")
        .navigationDestination(for: UserMangaCollection.self) { item in
            TVMangaDetailView(
                item: item,
                onSave: { readingVolume, volumesOwned, isComplete in
                    try await cloudVM.addToCollection(
                        manga: item.manga,
                        volumesOwned: volumesOwned,
                        readingVolume: readingVolume,
                        completeCollection: isComplete
                    )
                },
                onDelete: {
                    try await cloudVM.removeFromCollection(mangaId: item.manga.id)
                },
                onRefresh: {
                    await cloudVM.loadCollection()
                }
            )
        }
        .navigationDestination(for: UserCollection.self) { item in
            TVMangaDetailView(
                item: item,
                onSave: { readingVolume, volumesOwned, isComplete in
                    let dataContainer = DataContainer(modelContainer: modelContext.container)
                    try await dataContainer.updateUserStats(
                        mangaId: item.manga.id,
                        currentVolume: readingVolume,
                        volumesOwned: volumesOwned
                    )
                },
                onDelete: {
                    let dataContainer = DataContainer(modelContainer: modelContext.container)
                    try await dataContainer.removeFromCollection(mangaId: item.manga.id)
                },
                onRefresh: { }
            )
        }
    }

    // MARK: - Collection Content

    private var collectionContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 60) {
                // Refresh Button (solo cloud)
                if authVM.isAuthenticated {
                    refreshButton
                }

                // Stats Header
                statsHeader

                // Secciones
                if authVM.isAuthenticated {
                    cloudSections
                } else {
                    localSections
                }

                Spacer(minLength: 100)
            }
            .padding(.vertical, 50)
        }
    }

    // MARK: - Refresh Button

    private var refreshButton: some View {
        HStack {
            Spacer()
            Button {
                Task {
                    await cloudVM.loadCollection()
                }
            } label: {
                if cloudVM.state.isLoading {
                    ProgressView()
                        .frame(width: 40, height: 40)
                } else {
                    Label("action_refresh", systemImage: "arrow.clockwise")
                        .font(.system(size: 28, weight: .semibold))
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 80)
        .focusSection()
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        Button { } label: {
            TVStatsHeader(
                totalMangas: totalMangas,
                completedMangas: completedMangas,
                overallProgress: overallProgress
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 80)
        .focusSection()
    }

    // MARK: - Cloud Sections

    private var cloudSections: some View {
        Group {
            ForEach(DemographicsConfig.list) { config in
                let items = cloudVM.cloudCollection.filter { item in
                    item.manga.demographics.contains { $0.demographic == config.id }
                }
                if !items.isEmpty {
                    TVCollectionSection(
                        title: config.title,
                        icon: config.icon,
                        color: config.color
                    ) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            NavigationLink(value: item) {
                                TVCollectionCardLabel(item: item, loadDelay: Double(index) * 0.1)
                            }
                            .buttonStyle(.card)
                        }
                    }
                }
            }

            let otherItems = cloudVM.cloudCollection.filter { $0.manga.demographics.isEmpty }
            if !otherItems.isEmpty {
                TVCollectionSection(
                    title: "section_other",
                    icon: "square.grid.2x2",
                    color: .gray
                ) {
                    ForEach(Array(otherItems.enumerated()), id: \.element.id) { index, item in
                        NavigationLink(value: item) {
                            TVCollectionCardLabel(item: item, loadDelay: Double(index) * 0.1)
                        }
                        .buttonStyle(.card)
                    }
                }
            }
        }
    }

    // MARK: - Local Sections

    private var localSections: some View {
        Group {
            ForEach(DemographicsConfig.list) { config in
                let items = localCollection.filter { item in
                    item.manga.demographicNames.contains(config.id)
                }
                if !items.isEmpty {
                    TVCollectionSection(
                        title: config.title,
                        icon: config.icon,
                        color: config.color
                    ) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            NavigationLink(value: item) {
                                TVCollectionCardLabel(item: item, loadDelay: Double(index) * 0.1)
                            }
                            .buttonStyle(.card)
                        }
                    }
                }
            }

            let otherItems = localCollection.filter { $0.manga.demographicNames.isEmpty }
            if !otherItems.isEmpty {
                TVCollectionSection(
                    title: "section_other",
                    icon: "square.grid.2x2",
                    color: .gray
                ) {
                    ForEach(Array(otherItems.enumerated()), id: \.element.id) { index, item in
                        NavigationLink(value: item) {
                            TVCollectionCardLabel(item: item, loadDelay: Double(index) * 0.1)
                        }
                        .buttonStyle(.card)
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var authVM = AuthViewModel()
    TVCollectionView(cloudVM: CloudCollectionViewModel(authVM: authVM))
        .environment(authVM)
        .modelContainer(for: [MangaModel.self, UserCollection.self, OwnedVolume.self], inMemory: true)
}
