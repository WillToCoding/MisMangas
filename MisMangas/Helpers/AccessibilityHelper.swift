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
    func accessibilityAnimation<V: Equatable>(
        _ animation: Animation?,
        value: V,
        reduceMotion: Bool
    ) -> some View {
        Group {
            if reduceMotion {
                self
            } else {
                self.animation(animation, value: value)
            }
        }
    }
}

// MARK: - Reduce Transparency Support

extension View {
    /// Aplica material solo si Reduce Transparency está desactivado
    /// Uso: .accessibilityBackground(material: .ultraThinMaterial, reduceTransparency: reduceTransparency)
    func accessibilityBackground(
        material: Material,
        reduceTransparency: Bool,
        fallbackColor: Color = .systemBackground
    ) -> some View {
        Group {
            if reduceTransparency {
                self.background(fallbackColor)
            } else {
                self.background(material)
            }
        }
    }

    /// Aplica blur solo si Reduce Transparency está desactivado
    func accessibilityBlur(
        radius: CGFloat,
        reduceTransparency: Bool
    ) -> some View {
        Group {
            if reduceTransparency {
                self
            } else {
                self.blur(radius: radius)
            }
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
        #if os(iOS) || os(visionOS)
        Color(uiColor: .systemBackground)
        #elseif os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #elseif os(tvOS)
        Color.black
        #else
        Color.white
        #endif
    }

    /// Color de fondo secundario del sistema
    static var secondarySystemBackground: Color {
        #if os(iOS) || os(visionOS)
        Color(uiColor: .secondarySystemBackground)
        #elseif os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #elseif os(tvOS)
        Color.gray.opacity(0.2)
        #else
        Color.gray.opacity(0.1)
        #endif
    }
}

// MARK: - Accessibility Header

extension View {
    /// Marca como header semántico con nivel de jerarquía
    ///
    /// Reemplaza:
    /// ```swift
    /// .accessibilityAddTraits(.isHeader)
    /// .accessibilityHeading(.h2)
    /// ```
    ///
    /// Uso:
    /// ```swift
    /// Text("Sección")
    ///     .accessibilityHeader(.h2)
    /// ```
    func accessibilityHeader(_ level: AccessibilityHeadingLevel = .h2) -> some View {
        self
            .accessibilityAddTraits(.isHeader)
            .accessibilityHeading(level)
    }
}

// MARK: - Accessibility Card

extension View {
    /// Configura accesibilidad completa para cards/botones interactivos
    ///
    /// Reemplaza:
    /// ```swift
    /// .accessibilityElement(children: .combine)
    /// .accessibilityLabel(label)
    /// .accessibilityValue(value)
    /// .accessibilityHint(hint)
    /// .accessibilityAddTraits(.isButton)
    /// ```
    ///
    /// Uso:
    /// ```swift
    /// VStack { ... }
    ///     .accessibilityCard(
    ///         label: "Naruto",
    ///         value: "Puntuación 8.5",
    ///         hint: "Doble toque para ver detalles"
    ///     )
    /// ```
    func accessibilityCard(label: String, value: String? = nil, hint: String? = nil) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityValue(value ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Accessibility Selectable

extension View {
    /// Configura accesibilidad para elementos seleccionables (chips, filtros)
    ///
    /// Reemplaza:
    /// ```swift
    /// .accessibilityLabel(label)
    /// .accessibilityAddTraits(isSelected ? .isSelected : [])
    /// .accessibilityHint(isSelected ? "deseleccionar" : "seleccionar")
    /// ```
    ///
    /// Uso:
    /// ```swift
    /// Text("Acción")
    ///     .accessibilitySelectable(label: "Género Acción", isSelected: true)
    /// ```
    func accessibilitySelectable(label: String, isSelected: Bool) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityHint(isSelected
                ? String(localized: "accessibility_tap_deselect")
                : String(localized: "accessibility_tap_select"))
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
