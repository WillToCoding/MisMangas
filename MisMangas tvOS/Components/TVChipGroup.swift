//
//  TVChipGroup.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 22/2/26.
//

import SwiftUI

struct TVChipGroup: View {
    let items: [String]
    @Binding var selection: Set<String>
    let color: Color

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(items, id: \.self) { item in
                    Button {
                        if selection.contains(item) {
                            selection.remove(item)
                        } else {
                            selection.insert(item)
                        }
                    } label: {
                        Text(localizedAPIValue(item))
                            .font(.system(size: 26, weight: .medium))
                            .padding(.horizontal, 24)
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
        .focusSection()
    }
}

#Preview {
    @Previewable @State var selection: Set<String> = ["Action"]
    TVChipGroup(
        items: ["Action", "Adventure", "Comedy", "Drama", "Fantasy"],
        selection: $selection,
        color: .blue
    )
    .padding(40)
}
