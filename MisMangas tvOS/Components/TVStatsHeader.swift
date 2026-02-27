//
//  TVStatsHeader.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 25/2/26.
//

import SwiftUI

struct TVStatsHeader: View {
    let totalMangas: Int
    let completedMangas: Int
    let overallProgress: Int

    var body: some View {
        HStack(spacing: 0) {
            // Total Mangas
            TVStatItem(
                value: "\(totalMangas)",
                label: "collection_mangas",
                color: .blue,
                icon: "books.vertical.fill"
            )

            Spacer()

            // Completados
            TVStatItem(
                value: "\(completedMangas)",
                label: "collection_completed",
                color: .green,
                icon: "checkmark.circle.fill"
            )

            Spacer()

            // Progreso
            TVStatItem(
                value: "\(overallProgress)%",
                label: "collection_progress",
                color: .orange,
                icon: "chart.line.uptrend.xyaxis"
            )
        }
        .padding(40)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Stat Item

struct TVStatItem: View {
    let value: String
    let label: LocalizedStringKey
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 8) {
                Text(value)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(color)

                Text(label)
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    TVStatsHeader(
        totalMangas: 12,
        completedMangas: 4,
        overallProgress: 65
    )
    .padding(80)
}
