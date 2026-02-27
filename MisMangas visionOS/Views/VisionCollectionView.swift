//
//  VisionCollectionView.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct VisionCollectionView: View {
    @Bindable var cloudVM: CloudCollectionViewModel
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Stats

    private var totalMangas: Int {
        cloudVM.cloudCollection.count
    }

    private var completedMangas: Int {
        cloudVM.cloudCollection.filter { item in
            guard let total = item.manga.volumes else { return false }
            return item.readingVolume == total
        }.count
    }

    private var overallProgress: Int {
        let items = cloudVM.cloudCollection.compactMap { item -> (current: Int, total: Int)? in
            guard let total = item.manga.volumes, total > 0 else { return nil }
            return (item.readingVolume ?? 0, total)
        }
        guard !items.isEmpty else { return 0 }
        let totalRead = items.reduce(0) { $0 + $1.current }
        let totalVolumes = items.reduce(0) { $0 + $1.total }
        return totalVolumes > 0 ? Int((Double(totalRead) / Double(totalVolumes)) * 100) : 0
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 50) {
                // Stats Header
                if !cloudVM.cloudCollection.isEmpty {
                    VisionStatsHeader(
                        totalMangas: totalMangas,
                        completedMangas: completedMangas,
                        overallProgress: overallProgress
                    )
                    .padding(.horizontal, 60)
                }

                // Sections by demographic
                ForEach(DemographicsConfig.list) { config in
                    let items = cloudVM.cloudCollection.filter { item in
                        item.manga.demographics.contains { $0.demographic == config.id }
                    }
                    if !items.isEmpty {
                        VisionHorizontalSection(
                            title: config.title,
                            icon: config.icon,
                            color: config.color
                        ) {
                            ForEach(items) { item in
                                NavigationLink(value: item.id) {
                                    VisionCollectionCard(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Mangas without demographic
                let otherItems = cloudVM.cloudCollection.filter { $0.manga.demographics.isEmpty }
                if !otherItems.isEmpty {
                    VisionHorizontalSection(
                        title: "section_other",
                        icon: "square.grid.2x2",
                        color: .gray
                    ) {
                        ForEach(otherItems) { item in
                            NavigationLink(value: item.id) {
                                VisionCollectionCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer(minLength: 60)
            }
            .padding(.vertical, 40)
        }
        .navigationTitle("nav_collection")
        .navigationDestination(for: String.self) { itemId in
            if let item = cloudVM.cloudCollection.first(where: { $0.id == itemId }) {
                VisionMangaDetailView(
                    item: item,
                    onSave: { readingVolume, volumesOwned, isComplete in
                        try await cloudVM.addToCollection(
                            manga: item.manga,
                            volumesOwned: volumesOwned,
                            readingVolume: readingVolume,
                            completeCollection: isComplete
                        )
                        await cloudVM.loadCollection()
                    },
                    onDelete: {
                        try await cloudVM.removeFromCollection(mangaId: item.manga.id)
                        await cloudVM.loadCollection()
                    }
                )
            }
        }
        .refreshable {
            await cloudVM.loadCollection()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                Task {
                    await cloudVM.loadCollection()
                }
            }
        }
        .ornament(attachmentAnchor: .scene(.top)) {
            if cloudVM.state.isLoading {
                ProgressView()
                    .padding()
                    .glassBackgroundEffect()
            }
        }
    }
}

#Preview {
    let authVM = AuthViewModel()
    NavigationStack {
        VisionCollectionView(cloudVM: CloudCollectionViewModel(authVM: authVM))
    }
}
