//
//  CollectionStatsHeader.swift
//  MisMangas
//
//  Created by Juan Carlos on 26/2/26.
//

import SwiftUI

struct CollectionStatsHeader: View {
    let totalMangas: Int
    let completedMangas: Int
    let overallProgress: Int
    var isCloud: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            // Total Mangas
            StatItem(
                value: "\(totalMangas)",
                label: "collection_mangas",
                color: .blue,
                icon: "books.vertical.fill"
            )

            Spacer()

            // Completados
            StatItem(
                value: "\(completedMangas)",
                label: "collection_completed",
                color: .green,
                icon: "checkmark.circle.fill"
            )

            Spacer()

            // Progreso
            StatItem(
                value: "\(overallProgress)%",
                label: "collection_progress",
                color: .orange,
                icon: "chart.line.uptrend.xyaxis"
            )

            Spacer()

            // Cloud/Local indicator
            Image(systemName: isCloud ? "cloud.fill" : "internaldrive.fill")
                .font(.title2)
                .foregroundStyle(isCloud ? .blue : .green)
                .accessibilityHidden(true)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let storageType = isCloud
            ? String(localized: "accessibility_cloud_collection")
            : String(localized: "accessibility_local_collection")
        let total = String(localized: "accessibility_total_mangas \(totalMangas)")
        let completed = String(localized: "accessibility_completed_mangas \(completedMangas)")
        let progress = String(localized: "accessibility_progress \(overallProgress)")
        return "\(storageType), \(total), \(completed), \(progress)"
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let value: String
    let label: LocalizedStringKey
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundStyle(color)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        CollectionStatsHeader(
            totalMangas: 12,
            completedMangas: 4,
            overallProgress: 65,
            isCloud: true
        )

        CollectionStatsHeader(
            totalMangas: 8,
            completedMangas: 2,
            overallProgress: 40,
            isCloud: false
        )
    }
    .padding()
}
