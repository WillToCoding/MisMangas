//
//  VisionHorizontalSection.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct VisionHorizontalSection<Content: View>: View {
    let title: LocalizedStringKey
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Label(title, systemImage: icon)
                .font(.title.bold())
                .foregroundStyle(color)
                .padding(.horizontal, 60)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    content()
                }
                .padding(.horizontal, 60)
            }
        }
    }
}

#Preview {
    VisionHorizontalSection(
        title: "Popular",
        icon: "flame.fill",
        color: .orange
    ) {
        ForEach(0..<5) { i in
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.3))
                .frame(width: 150, height: 200)
                .overlay(Text("Item \(i + 1)"))
        }
    }
}
