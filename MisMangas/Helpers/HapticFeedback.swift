//
//  HapticFeedback.swift
//  MisMangas
//
//  Created by Juan Carlos on 25/12/25.
//

import SwiftUI

#if os(iOS)
import UIKit

/// Helper para feedback háptico consistente en toda la app
/// Uso: HapticFeedback.success.trigger()
enum HapticFeedback: Sendable {
    /// Acción completada exitosamente (guardar, añadir a colección)
    case success
    /// Error o acción fallida
    case error
    /// Advertencia (eliminar, acción destructiva)
    case warning
    /// Impacto ligero (selección, toggle)
    case light
    /// Impacto medio (botón importante)
    case medium
    /// Impacto fuerte (acción significativa)
    case heavy
    /// Cambio de selección (stepper, picker)
    case selection

    /// Ejecuta el feedback háptico en el main thread
    @MainActor
    func trigger() {
        switch self {
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}
#elseif os(macOS)
import AppKit

enum HapticFeedback: Sendable {
    case success, error, warning, light, medium, heavy, selection

    @MainActor
    func trigger() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .levelChange,
            performanceTime: .default
        )
    }
}
#endif
