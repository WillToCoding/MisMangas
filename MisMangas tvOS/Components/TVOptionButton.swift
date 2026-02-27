//
//  TVOptionButton.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 22/2/26.
//

import SwiftUI

struct TVOptionButton: View {
    let isSelected: Bool
    let color: Color
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 26, weight: .medium))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    isSelected ? color : color.opacity(0.2),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? (color == .yellow ? .black : .white) : color)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 20) {
        TVOptionButton(isSelected: true, color: .yellow, label: "≥ 8.0") { }
        TVOptionButton(isSelected: false, color: .yellow, label: "≥ 9.0") { }
        TVOptionButton(isSelected: true, color: .green, label: "Publishing") { }
        TVOptionButton(isSelected: false, color: .green, label: "Finished") { }
    }
    .padding(40)
}
