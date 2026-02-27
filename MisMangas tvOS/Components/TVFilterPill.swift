//
//  TVFilterPill.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 22/2/26.
//

import SwiftUI

struct TVFilterPill: View {
    let text: String
    let color: Color
    let onRemove: () -> Void

    var body: some View {
        Button {
            onRemove()
        } label: {
            HStack(spacing: 8) {
                Text(text)
                Image(systemName: "xmark.circle.fill")
            }
            .font(.system(size: 22, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color.opacity(0.2), in: Capsule())
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 12) {
        TVFilterPill(text: "Shonen", color: .purple) { }
        TVFilterPill(text: "Action", color: .blue) { }
        TVFilterPill(text: "≥ 8.0", color: .yellow) { }
    }
    .padding(40)
}
