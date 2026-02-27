//
//  FilterChipView.swift
//  MisMangas
//
//  Created by Juan Carlos on 26/2/26.
//

import SwiftUI

/// Chip de filtro reutilizable para selección múltiple
struct FilterChipView: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .foregroundStyle(isSelected ? color : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .accessibilitySelectable(label: title, isSelected: isSelected)
    }
}

#Preview {
    HStack {
        FilterChipView(title: "Action", isSelected: true, color: .blue) {}
        FilterChipView(title: "Comedy", isSelected: false, color: .blue) {}
        FilterChipView(title: "Drama", isSelected: true, color: .purple) {}
    }
    .padding()
}
