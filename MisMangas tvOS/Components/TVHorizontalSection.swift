//
//  TVHorizontalSection.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 22/2/26.
//

import SwiftUI

struct TVHorizontalSection<Content: View>: View {
    let title: LocalizedStringKey
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            Label(title, systemImage: icon)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(color)
                .padding(.horizontal, 80)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 40) {
                    content()
                }
                .padding(.horizontal, 80)
                .padding(.vertical, 20)
            }
            .focusSection()
        }
    }
}

#Preview {
    TVHorizontalSection(
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
