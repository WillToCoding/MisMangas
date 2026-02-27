//
//  MacStatsHeader.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 26/02/26.
//

import SwiftUI

struct MacStatsHeader: View {
    let totalMangas: Int
    let completedMangas: Int
    let overallProgress: Int
    let isCloud: Bool

    var body: some View {
        HStack(spacing: 32) {
            MacStatItem(
                value: "\(totalMangas)",
                label: "collection_mangas",
                color: .blue,
                icon: "books.vertical.fill"
            )

            Divider()
                .frame(height: 40)

            MacStatItem(
                value: "\(completedMangas)",
                label: "collection_completed",
                color: .green,
                icon: "checkmark.circle.fill"
            )

            Divider()
                .frame(height: 40)

            MacStatItem(
                value: "\(overallProgress)%",
                label: "collection_progress",
                color: .orange,
                icon: "chart.line.uptrend.xyaxis"
            )

            Spacer()

            if isCloud {
                Image(systemName: "cloud.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .padding(8)
                    .background(.blue.opacity(0.1), in: Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Stat Item

struct MacStatItem: View {
    let value: String
    let label: LocalizedStringKey
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(color)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    MacStatsHeader(
        totalMangas: 24,
        completedMangas: 8,
        overallProgress: 72,
        isCloud: true
    )
    .padding()
}
