//
//  WatchCollectionView.swift
//  MisMangas watchOS Watch App
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct WatchCollectionView: View {
    @Bindable var cloudVM: CloudCollectionViewModel
    @State private var hasAppeared = false

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
        ZStack {
            List {
                statsHeader
                mangaList
            }
            .refreshable {
                await cloudVM.loadCollection()
            }
            .task {
                if !hasAppeared {
                    hasAppeared = true
                    await cloudVM.loadCollection()
                }
            }
            .navigationTitle("nav_collection")
            .navigationDestination(for: String.self) { itemId in
                if let item = cloudVM.cloudCollection.first(where: { $0.id == itemId }) {
                    WatchMangaDetailView(item: item) {
                        Task { await cloudVM.loadCollection() }
                    }
                }
            }

            loadingOverlay
        }
    }

    // MARK: - Sections

    private var statsHeader: some View {
        Section {
            HStack {
                statItem(value: "\(totalMangas)", label: "collection_mangas", color: .primary)
                Spacer()
                statItem(value: "\(completedMangas)", label: "collection_completed", color: .green)
                Spacer()
                statItem(value: "\(overallProgress)%", label: "collection_progress", color: .blue)
            }
            .lineLimit(1)
        }
    }

    private func statItem(value: String, label: LocalizedStringKey, color: Color) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .minimumScaleFactor(0.8)
        }
    }

    private var mangaList: some View {
        ForEach(cloudVM.cloudCollection) { item in
            NavigationLink(value: item.id) {
                WatchMangaRow(itemId: item.id, cloudVM: cloudVM)
            }
            .id("\(item.id)-\(item.readingVolume ?? 0)")
        }
    }

    private var loadingOverlay: some View {
        Group {
            if cloudVM.state.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
    }
}

#Preview {
    let authVM = AuthViewModel()
    NavigationStack {
        WatchCollectionView(cloudVM: CloudCollectionViewModel(authVM: authVM))
            .environment(authVM)
    }
}
