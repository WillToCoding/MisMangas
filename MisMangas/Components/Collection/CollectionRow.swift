//
//  CollectionRow.swift
//  MisMangas
//
//  Created by Juan Carlos on 1/2/26.
//

import SwiftUI

// MARK: - Generic Collection Row
struct CollectionRow<Item: CollectionItem>: View {
    let item: Item

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            coverImage
            mangaInfo
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(item.isCloudSynced ? String(localized: "accessibility_tap_edit_progress") : "")
    }

    // MARK: - Cover Image (con caché)
    private var coverImage: some View {
        CachedCoverImage(url: item.collectionCoverURL)
            .accessibilityHidden(true)
    }

    // MARK: - Manga Info
    private var mangaInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.collectionTitle)
                .font(.headline)
                .lineLimit(2)

            scoreLabel
            collectionStatus
            readingProgress

            if item.isCloudSynced {
                cloudBadge
            }
        }
    }

    private var scoreLabel: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
                .font(.caption)
            Text(item.collectionScore.formatted(.number.precision(.fractionLength(2))))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var collectionStatus: some View {
        if item.collectionIsComplete {
            Label("collection_complete", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        } else {
            let total = item.collectionTotalVolumes.map(String.init) ?? "?"
            Text("volumes_owned_of \(item.collectionVolumesOwned.count) \(total)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var readingProgress: some View {
        if let currentReading = item.collectionReadingVolume {
            Label("vol_current \(currentReading)", systemImage: "book.fill")
                .font(.caption2)
                .foregroundStyle(.blue)
        }
    }

    private var cloudBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "cloud.fill")
                .font(.caption2)
            Text("collection_cloud")
                .font(.caption2)
        }
        .foregroundStyle(.blue.opacity(0.7))
        .accessibilityHidden(true)
    }

    // MARK: - Accessibility
    private var accessibilityLabel: String {
        var label = item.collectionTitle
        label += ", " + String(localized: "accessibility_score \(item.collectionScore.formatted(.number.precision(.fractionLength(1))))")

        if item.collectionIsComplete {
            label += ", " + String(localized: "accessibility_collection_complete")
        } else {
            label += ", \(item.collectionVolumesOwned.count) " + String(localized: "accessibility_volumes_owned")
        }

        if let currentReading = item.collectionReadingVolume {
            label += ", " + String(localized: "accessibility_reading_volume \(currentReading)")
        }

        if item.isCloudSynced {
            label += ", " + String(localized: "accessibility_synced_cloud")
        }

        return label
    }
}

// MARK: - Previews
#Preview("Local Collection") {
    List {
        ForEach(PreviewData.shared.allCollections) { collection in
            CollectionRow(item: collection)
        }
    }
}

#Preview("Cloud Collection") {
    List {
        CollectionRow(item: UserMangaCollection(
            id: "1",
            manga: .test,
            completeCollection: false,
            volumesOwned: [1, 2, 3],
            readingVolume: 2
        ))
    }
}
