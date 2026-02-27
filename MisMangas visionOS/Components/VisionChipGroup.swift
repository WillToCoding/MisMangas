//
//  VisionChipGroup.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 26/02/26.
//

import SwiftUI

struct VisionChipGroup: View {
    let items: [String]
    @Binding var selection: Set<String>
    let color: Color

    var body: some View {
        FlowLayout(spacing: 12) {
            ForEach(items, id: \.self) { item in
                Button {
                    if selection.contains(item) {
                        selection.remove(item)
                    } else {
                        selection.insert(item)
                    }
                } label: {
                    Text(localizedAPIValue(item))
                        .font(.title3)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            selection.contains(item) ? color : color.opacity(0.2),
                            in: Capsule()
                        )
                        .foregroundStyle(selection.contains(item) ? .white : color)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    @Previewable @State var selection: Set<String> = ["Action", "Comedy"]

    VisionChipGroup(
        items: ["Action", "Comedy", "Drama", "Fantasy", "Horror"],
        selection: $selection,
        color: .blue
    )
    .padding()
}
