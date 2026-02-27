//
//  TVCollectionSection.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct TVCollectionSection<Content: View>: View {
    let title: LocalizedStringKey
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Header
            Label(title, systemImage: icon)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(color)
                .padding(.horizontal, 80)

            // Horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 40) {
                    content()
                }
                .padding(.horizontal, 80)
            }
            .focusSection()
        }
    }
}

#Preview {
    TVCollectionSection(
        title: "Shonen",
        icon: "flame.fill",
        color: .orange
    ) {
        ForEach(0..<5) { index in
            RoundedRectangle(cornerRadius: 16)
                .fill(.gray.opacity(0.3))
                .frame(width: 220, height: 330)
                .overlay {
                    Text("Item \(index + 1)")
                        .font(.title2)
                }
        }
    }
    .padding(.vertical, 40)
}
