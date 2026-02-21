//
//  AccessibilityHelper.swift
//  MisMangas
//
//  Created by Juan Carlos on 25/12/25.
//

import SwiftUI

// MARK: - Reduce Motion Support

extension View {
    /// Aplica animación solo si Reduce Motion está desactivado
    /// Uso: .accessibilityAnimation(.spring(), value: isExpanded, reduceMotion: reduceMotion)
    @ViewBuilder
    func accessibilityAnimation<V: Equatable>(
        _ animation: Animation?,
        value: V,
        reduceMotion: Bool
    ) -> some View {
        if reduceMotion {
            self
        } else {
            self.animation(animation, value: value)
        }
    }
}

// MARK: - Reduce Transparency Support

extension View {
    /// Aplica material solo si Reduce Transparency está desactivado
    /// Uso: .accessibilityBackground(material: .ultraThinMaterial, reduceTransparency: reduceTransparency)
    @ViewBuilder
    func accessibilityBackground(
        material: Material,
        reduceTransparency: Bool,
        fallbackColor: Color = .systemBackground
    ) -> some View {
        if reduceTransparency {
            self.background(fallbackColor)
        } else {
            self.background(material)
        }
    }

    /// Aplica blur solo si Reduce Transparency está desactivado
    @ViewBuilder
    func accessibilityBlur(
        radius: CGFloat,
        reduceTransparency: Bool
    ) -> some View {
        if reduceTransparency {
            self
        } else {
            self.blur(radius: radius)
        }
    }
}

// MARK: - Hit Targets

extension View {
    /// Asegura área táctil mínima de 44x44pt (recomendación Apple HIG)
    func accessibleHitTarget() -> some View {
        self
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }
}

// MARK: - Color Extensions

extension Color {
    /// Color de fondo del sistema (adaptativo a light/dark mode)
    static var systemBackground: Color {
        #if os(iOS) || os(tvOS) || os(visionOS)
        Color(uiColor: .systemBackground)
        #elseif os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.white
        #endif
    }

    /// Color de fondo secundario del sistema
    static var secondarySystemBackground: Color {
        #if os(iOS) || os(tvOS) || os(visionOS)
        Color(uiColor: .secondarySystemBackground)
        #elseif os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color.gray.opacity(0.1)
        #endif
    }
}

// MARK: - Preview Helpers

extension View {
    /// Preview con Dynamic Type grande (Accessibility 3)
    func previewAccessibilitySize() -> some View {
        self.dynamicTypeSize(.accessibility3)
    }

    /// Preview con Dynamic Type específico
    func previewDynamicType(_ size: DynamicTypeSize) -> some View {
        self.dynamicTypeSize(size)
    }
}
