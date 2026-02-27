//
//  MacFlowLayout.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 22/2/26.
//

import SwiftUI

/// Layout que organiza vistas en filas, pasando a la siguiente fila cuando no hay espacio
struct MacFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.frames[index].minX,
                    y: bounds.minY + result.frames[index].minY
                ),
                proposal: .unspecified
            )
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    MacFlowLayout(spacing: 8) {
        ForEach(["Action", "Adventure", "Comedy", "Drama", "Fantasy"], id: \.self) { tag in
            Text(tag)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.blue.opacity(0.15))
                .clipShape(Capsule())
        }
    }
    .padding()
}
