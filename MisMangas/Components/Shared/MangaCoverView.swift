//
//  MangaCoverView.swift
//  MisMangas
//
//  Created by Juan Carlos on 1/2/26.
//

import SwiftUI

/// Vista reutilizable para mostrar covers de manga con caché y animaciones hero
struct MangaCoverView: View {
    let url: URL?
    let namespace: Namespace.ID
    var size: CoverSize = .small

    @State private var coverVM = MangaCoverVM()

    enum CoverSize {
        case small   // Para listas (90x135)
        case medium  // Para grids (120x180)
        case large   // Para detalle (180x270)

        var width: CGFloat {
            switch self {
            case .small: return 90
            case .medium: return 120
            case .large: return 180
            }
        }

        var height: CGFloat {
            switch self {
            case .small: return 135
            case .medium: return 180
            case .large: return 270
            }
        }
    }

    private var transitionID: String {
        url?.absoluteString ?? UUID().uuidString
    }

    var body: some View {
        Group {
            if let image = coverVM.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                placeholder
            }
        }
        .matchedTransitionSource(id: transitionID, in: namespace)
        .onAppear {
            coverVM.getImage(url: url)
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.gray.opacity(0.2))
            .frame(width: size.width, height: size.height)
            .overlay {
                if coverVM.isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "book.closed")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            }
    }
}

/// Vista para el detalle que recibe la animación zoom
struct MangaCoverDetailView: View {
    let url: URL?
    let namespace: Namespace.ID
    var size: MangaCoverView.CoverSize = .large

    @State private var coverVM = MangaCoverVM()

    private var transitionID: String {
        url?.absoluteString ?? UUID().uuidString
    }

    var body: some View {
        Group {
            if let image = coverVM.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 8)
            } else {
                placeholder
            }
        }
        .navigationTransition(.zoom(sourceID: transitionID, in: namespace))
        .onAppear {
            coverVM.getImage(url: url)
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.gray.opacity(0.2))
            .frame(width: size.width, height: size.height)
            .overlay {
                if coverVM.isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "book.closed")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            }
            .shadow(radius: 8)
    }
}

#Preview {
    @Previewable @Namespace var namespace

    VStack(spacing: 20) {
        MangaCoverView(
            url: URL(string: "https://cdn.myanimelist.net/images/manga/1/267793l.jpg"),
            namespace: namespace,
            size: .small
        )

        MangaCoverView(
            url: URL(string: "https://cdn.myanimelist.net/images/manga/1/267793l.jpg"),
            namespace: namespace,
            size: .medium
        )

        MangaCoverDetailView(
            url: URL(string: "https://cdn.myanimelist.net/images/manga/1/267793l.jpg"),
            namespace: namespace
        )
    }
}
