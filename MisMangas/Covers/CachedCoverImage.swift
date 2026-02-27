//
//  CachedCoverImage.swift
//  MisMangas
//
//  Created by Juan Carlos on 1/2/26.
//

import SwiftUI

/// Vista simple de cover con caché, sin animaciones hero
/// Usar en sheets, modals y vistas secundarias donde no se necesita hero animation
struct CachedCoverImage: View {
    let url: URL?
    var width: CGFloat = 60
    var height: CGFloat = 90
    var cornerRadius: CGFloat = 8

    @State private var coverVM = MangaCoverVM()

    var body: some View {
        Group {
            if let image = coverVM.image {
                #if os(iOS)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                #elseif os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                #endif
            } else {
                placeholder
            }
        }
        .task(id: url) {
            coverVM.image = nil
            coverVM.getImage(url: url)
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.gray.opacity(0.2))
            .frame(width: width, height: height)
            .overlay {
                if coverVM.isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "book.closed")
                        .foregroundStyle(.secondary)
                }
            }
    }
}

#Preview {
    VStack {
        CachedCoverImage(
            url: URL(string: "https://cdn.myanimelist.net/images/manga/1/267793l.jpg")
        )

        CachedCoverImage(
            url: URL(string: "https://cdn.myanimelist.net/images/manga/1/267793l.jpg"),
            width: 90,
            height: 135,
            cornerRadius: 10
        )
    }
}
