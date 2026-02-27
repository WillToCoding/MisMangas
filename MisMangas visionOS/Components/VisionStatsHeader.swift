//
//  VisionStatsHeader.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 26/02/26.
//

import SwiftUI

struct VisionStatsHeader: View {
    let totalMangas: Int
    let completedMangas: Int
    let overallProgress: Int
    var isCloud: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            VisionStatItem(
                value: "\(totalMangas)",
                label: "collection_mangas",
                color: .blue,
                icon: "books.vertical.fill"
            )

            Spacer()

            VisionStatItem(
                value: "\(completedMangas)",
                label: "collection_completed",
                color: .green,
                icon: "checkmark.circle.fill"
            )

            Spacer()

            VisionStatItem(
                value: "\(overallProgress)%",
                label: "collection_progress",
                color: .orange,
                icon: "chart.line.uptrend.xyaxis"
            )

            Spacer()

            Image(systemName: isCloud ? "cloud.fill" : "internaldrive.fill")
                .font(.system(size: 30))
                .foregroundStyle(isCloud ? .blue : .green)
        }
        .padding(30)
        .glassBackgroundEffect()
    }
}

// MARK: - Stat Item

struct VisionStatItem: View {
    let value: String
    let label: LocalizedStringKey
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 6) {
                Text(value)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(color)

                Text(label)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    VisionStatsHeader(
        totalMangas: 12,
        completedMangas: 4,
        overallProgress: 65
    )
    .padding(60)
}
