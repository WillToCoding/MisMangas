//
//  CollectionView+Sections.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI

// MARK: - Cloud Collection View

extension CollectionView {
    var cloudCollectionView: some View {
        Group {
            if cloudVM.state.isLoading {
                ProgressView("loading_collection")
            } else if let error = cloudVM.state.errorMessage {
                ContentUnavailableView(
                    "error_loading",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if cloudVM.cloudCollection.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        CollectionStatsHeader(
                            totalMangas: cloudVM.cloudCollection.count,
                            completedMangas: cloudCompletedCount,
                            overallProgress: cloudOverallProgress,
                            isCloud: true
                        )

                        ForEach(DemographicsConfig.list) { config in
                            let items = cloudItemsByDemographic(config.id)
                            if !items.isEmpty {
                                cloudSection(title: config.title, icon: config.icon, color: config.color, items: items)
                            }
                        }

                        let other = cloudItemsWithoutDemographic()
                        if !other.isEmpty {
                            cloudSection(title: "section_other", icon: "square.grid.2x2", color: .gray, items: other)
                        }

                        Spacer(minLength: 50)
                    }
                    .padding(.top)
                }
            }
        }
    }

    func cloudSection(title: LocalizedStringKey, icon: String, color: Color, items: [UserMangaCollection]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.title3.bold())
                    .foregroundStyle(color)

                Text("(\(items.count))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .accessibilityElement(children: .combine)
            .accessibilityHeader(.h2)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(items) { item in
                        NavigationLink(value: item.manga) {
                            MangaCard(manga: item.manga, namespace: namespace)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                collectionItemToEdit = item
                            } label: {
                                Label("action_edit", systemImage: "pencil")
                            }

                            Divider()

                            Button(role: .destructive) {
                                mangaToDelete = item.manga.id
                                showDeleteAlert = true
                            } label: {
                                Label("action_delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Local Collection View

extension CollectionView {
    var localCollectionView: some View {
        Group {
            if localCollection.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        CollectionStatsHeader(
                            totalMangas: localCollection.count,
                            completedMangas: localCompletedCount,
                            overallProgress: localOverallProgress,
                            isCloud: false
                        )

                        ForEach(DemographicsConfig.list) { config in
                            let items = localItemsByDemographic(config.id)
                            if !items.isEmpty {
                                localSection(title: config.title, icon: config.icon, color: config.color, items: items)
                            }
                        }

                        let other = localItemsWithoutDemographic()
                        if !other.isEmpty {
                            localSection(title: "section_other", icon: "square.grid.2x2", color: .gray, items: other)
                        }

                        Spacer(minLength: 50)
                    }
                    .padding(.top)
                }
            }
        }
    }

    func localSection(title: LocalizedStringKey, icon: String, color: Color, items: [UserCollection]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.title3.bold())
                    .foregroundStyle(color)

                Text("(\(items.count))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .accessibilityElement(children: .combine)
            .accessibilityHeader(.h2)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(items) { item in
                        NavigationLink(value: item.manga.toManga()) {
                            MangaCard(manga: item.manga.toManga(), namespace: namespace)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                localItemToEdit = item
                            } label: {
                                Label("action_edit", systemImage: "pencil")
                            }

                            Divider()

                            Button(role: .destructive) {
                                mangaToDelete = item.manga.id
                                showDeleteAlert = true
                            } label: {
                                Label("action_delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
