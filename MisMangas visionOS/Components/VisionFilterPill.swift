//
//  VisionFilterPill.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 26/02/26.
//

import SwiftUI

struct VisionFilterPill: View {
    let text: String
    let color: Color
    let onRemove: () -> Void

    var body: some View {
        Button {
            onRemove()
        } label: {
            HStack(spacing: 6) {
                Text(text)
                Image(systemName: "xmark.circle.fill")
            }
            .font(.callout)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.2), in: Capsule())
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        VisionFilterPill(text: "Action", color: .blue) { }
        VisionFilterPill(text: "Seinen", color: .purple) { }
        VisionFilterPill(text: "≥ 8.0", color: .yellow) { }
    }
    .padding()
}
