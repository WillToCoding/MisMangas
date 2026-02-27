//
//  WidgetStatsHeader.swift
//  MisMangas widget
//
//  Created by Juan Carlos on 26/2/26.
//

import SwiftUI

struct WidgetStatsHeader: View {
    let widgetData: WidgetData
    var compact: Bool = false

    var body: some View {
        HStack(spacing: compact ? 0 : 12) {
            // Total
            statItem(value: widgetData.totalInCollection, icon: "books.vertical.fill", color: .purple)

            // Completados y Leyendo - solo en Medium/Large
            if !compact {
                statItem(value: widgetData.completedCount, icon: "checkmark.circle.fill", color: .green)
                statItem(value: widgetData.readingCount, icon: "book.fill", color: .blue)
            }

            Spacer()

            // Progreso
            HStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(progressColor)
                Text("\(Int(widgetData.overallProgress * 100))%")
                    .font(compact ? .caption.bold() : .subheadline.bold())
                    .foregroundStyle(progressColor)
            }
        }
    }

    private func statItem(value: Int, icon: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(compact ? .caption2 : .caption)
                .foregroundStyle(color)
            Text("\(value)")
                .font(compact ? .caption.bold() : .subheadline.bold())
        }
    }

    private var progressColor: Color {
        switch widgetData.overallProgress {
        case 0..<0.3: return .red
        case 0.3..<0.7: return .orange
        default: return .green
        }
    }
}
