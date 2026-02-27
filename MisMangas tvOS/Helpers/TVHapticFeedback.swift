//
//  TVHapticFeedback.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 25/2/26.
//

import GameController
import CoreHaptics

/// Helper para feedback háptico en Siri Remote (2ª generación+)
///
/// Solo funciona en Siri Remote con soporte háptico.
/// En mandos antiguos o de terceros, falla silenciosamente.
///
/// ## Ejemplo de uso
/// ```swift
/// TVHapticFeedback.success.trigger()
/// TVHapticFeedback.celebration.trigger()
/// ```
enum TVHapticFeedback: Sendable {
    /// Acción completada (guardar progreso)
    case success
    /// Error o fallo
    case error
    /// Logro especial (completar manga)
    case celebration

    /// Ejecuta el feedback háptico en el Siri Remote
    @MainActor
    func trigger() {
        guard let controller = GCController.current,
              let haptics = controller.haptics,
              let engine = haptics.createEngine(withLocality: .default) else {
            return
        }

        do {
            try engine.start()

            let pattern = try hapticPattern()
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)

            // Detener el engine después de un tiempo
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                try? await engine.stop()
            }
        } catch {
            print("[TVHaptic] Error: \(error.localizedDescription)")
        }
    }

    private func hapticPattern() throws -> CHHapticPattern {
        switch self {
        case .success:
            // Vibración suave de confirmación
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0
            )
            return try CHHapticPattern(events: [event], parameters: [])

        case .error:
            // Vibración doble de error
            let event1 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0
            )
            let event2 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0.1
            )
            return try CHHapticPattern(events: [event1, event2], parameters: [])

        case .celebration:
            // Patrón de celebración: tres pulsos ascendentes
            let event1 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0
            )
            let event2 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0.1
            )
            let event3 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ],
                relativeTime: 0.2
            )
            return try CHHapticPattern(events: [event1, event2, event3], parameters: [])
        }
    }
}
