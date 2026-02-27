//
//  WidgetMangaCard.swift
//  MisMangas widget
//
//  Created by Juan Carlos on 26/02/26.
//

import SwiftUI

/// Componente unificado para mostrar un manga en widgets Medium y Large
struct WidgetMangaCard: View {
    let manga: WidgetManga

    /// Estilo del card según el tamaño del widget
    var style: Style = .medium

    enum Style {
        case small
        case medium
        case large

        var imageHeight: CGFloat {
            switch self {
            case .small: return 55
            case .medium: return 65
            case .large: return 75
            }
        }

        var titleFont: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption2
            case .large: return .caption
            }
        }

        var titleLineLimit: Int {
            switch self {
            case .small: return 1
            case .medium: return 1
            case .large: return 2
            }
        }

        /// Altura mínima del título para evitar descuadre
        var titleMinHeight: CGFloat? {
            switch self {
            case .small: return nil
            case .medium: return nil
            case .large: return 28
            }
        }

        var showProgressIcon: Bool {
            switch self {
            case .small: return false
            case .medium: return false
            case .large: return true
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            coverImage
            titleText
            progressSection
        }
    }

    // MARK: - Subviews

    private var coverImage: some View {
        Group {
            if let image = manga.localImage {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: style.imageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [.purple.opacity(0.6), .blue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: style.imageHeight)
                    .overlay {
                        Image(systemName: "book.closed")
                            .foregroundStyle(.white.opacity(0.7))
                    }
            }
        }
    }

    @ViewBuilder
    private var titleText: some View {
        let text = Text(manga.title)
            .font(style.titleFont)
            .fontWeight(style == .large ? .medium : .semibold)
            .lineLimit(style.titleLineLimit)
            .minimumScaleFactor(style == .large ? 0.8 : 1.0)

        if let minHeight = style.titleMinHeight {
            text.frame(minHeight: minHeight, alignment: .top)
        } else {
            text
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if style.showProgressIcon {
                HStack(spacing: 4) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 8))
                    Text(manga.progressText)
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            } else {
                Text(manga.progressText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: manga.progressPercentage)
                .tint(Color.accentColor)
        }
    }
}
