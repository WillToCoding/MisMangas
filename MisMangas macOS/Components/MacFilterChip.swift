//
//  MacFilterChip.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 22/2/26.
//

import SwiftUI

/// Chip de filtro reutilizable para selección múltiple
struct MacFilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    init(title: String, isSelected: Bool, color: Color = .blue, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .foregroundStyle(isSelected ? color : .primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        MacFilterChip(title: "Action", isSelected: true, color: .blue) {}
        MacFilterChip(title: "Comedy", isSelected: false, color: .blue) {}
        MacFilterChip(title: "Drama", isSelected: true, color: .purple) {}
    }
    .padding()
}
