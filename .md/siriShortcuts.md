# Siri Shortcuts - MisMangas

> **Objetivo:** Permitir al usuario interactuar con la app mediante comandos de voz y accesos rápidos.

---

## Funcionalidades Propuestas

### 1. "¿Qué estoy leyendo?"
- **Trigger:** "Oye Siri, ¿qué estoy leyendo?"
- **Respuesta:** Siri lee el nombre del manga actual y el volumen
- **Ejemplo:** "Estás leyendo One Piece, volumen 50 de 109"

### 2. "Siguiente volumen"
- **Trigger:** "Oye Siri, siguiente volumen de manga"
- **Acción:** Incrementa el volumen de lectura del manga activo
- **Respuesta:** "Actualizado a volumen 51"

### 3. "Mostrar mi colección"
- **Trigger:** "Oye Siri, mi colección de mangas"
- **Acción:** Abre la app en la vista de colección

---

## Arquitectura

### 1. Crear App Intent (iOS 16+)

```swift
// Intents/ShowCurrentReadingIntent.swift
import AppIntents

struct ShowCurrentReadingIntent: AppIntent {
    static var title: LocalizedStringResource = "Ver manga actual"
    static var description = IntentDescription("Muestra el manga que estás leyendo")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Obtener manga actual desde App Group o API
        guard let currentManga = await getCurrentReading() else {
            return .result(dialog: "No estás leyendo ningún manga actualmente")
        }

        let message = "Estás leyendo \(currentManga.title), volumen \(currentManga.currentVolume)"
        if let total = currentManga.totalVolumes {
            return .result(dialog: "\(message) de \(total)")
        }
        return .result(dialog: message)
    }

    private func getCurrentReading() async -> WidgetManga? {
        // Leer desde App Group (mismo que el widget)
        guard let defaults = UserDefaults(suiteName: "group.com.murtidev.MisMangas"),
              let data = defaults.data(forKey: "widgetMangaData"),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data),
              let first = widgetData.mangas.first else {
            return nil
        }
        return first
    }
}
```

### 2. Intent para Actualizar Volumen

```swift
// Intents/UpdateVolumeIntent.swift
import AppIntents

struct UpdateVolumeIntent: AppIntent {
    static var title: LocalizedStringResource = "Siguiente volumen"
    static var description = IntentDescription("Avanza al siguiente volumen del manga actual")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Aquí necesitarías:
        // 1. Obtener el manga actual
        // 2. Llamar a la API para actualizar el volumen
        // 3. Actualizar App Group para el widget

        // Ejemplo simplificado:
        return .result(dialog: "Volumen actualizado")
    }
}
```

### 3. Registrar Shortcuts

```swift
// Intents/MisMangasShortcuts.swift
import AppIntents

struct MisMangasShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowCurrentReadingIntent(),
            phrases: [
                "¿Qué estoy leyendo en \(.applicationName)?",
                "Mi manga actual en \(.applicationName)",
                "¿Qué manga leo en \(.applicationName)?"
            ],
            shortTitle: "Manga Actual",
            systemImageName: "book.fill"
        )

        AppShortcut(
            intent: UpdateVolumeIntent(),
            phrases: [
                "Siguiente volumen en \(.applicationName)",
                "Avanzar manga en \(.applicationName)"
            ],
            shortTitle: "Siguiente Volumen",
            systemImageName: "plus.circle"
        )
    }
}
```

---

## Archivos a Crear

```
MisMangas/
└── Intents/
    ├── ShowCurrentReadingIntent.swift
    ├── UpdateVolumeIntent.swift
    └── MisMangasShortcuts.swift
```

---

## Pasos de Implementación

### Paso 1: Crear carpeta Intents
```bash
mkdir -p MisMangas/Intents
```

### Paso 2: Crear ShowCurrentReadingIntent.swift
- Intent básico que lee desde App Group
- No requiere autenticación (datos ya cacheados)
- Devuelve diálogo de Siri

### Paso 3: Crear UpdateVolumeIntent.swift
- Intent que modifica datos
- Requiere token de autenticación
- Necesita acceso a KeychainHelper
- Llama a la API

### Paso 4: Crear MisMangasShortcuts.swift
- Registrar frases en español
- Definir iconos y títulos

### Paso 5: Testing
- Probar en dispositivo físico (Siri no funciona en simulador)
- Verificar que los shortcuts aparecen en la app Shortcuts
- Probar frases de voz

---

## Consideraciones

### Autenticación
- Para leer manga actual: No necesaria (usa App Group)
- Para actualizar volumen: Necesaria (usar token de Keychain)

### Idioma
- Las frases deben estar en español
- Siri adaptará variaciones automáticamente

### App Groups
- Reutilizar `group.com.murtidev.MisMangas`
- Los datos del widget sirven para los shortcuts

---

## Checklist

- [ ] Crear carpeta `Intents/`
- [ ] Implementar `ShowCurrentReadingIntent`
- [ ] Implementar `UpdateVolumeIntent`
- [ ] Registrar shortcuts en `MisMangasShortcuts`
- [ ] Añadir Siri capability en Xcode
- [ ] Testing en dispositivo físico
- [ ] Verificar frases en español

---

## Recursos

- [App Intents Documentation](https://developer.apple.com/documentation/appintents)
- [WWDC22 - Dive into App Intents](https://developer.apple.com/videos/play/wwdc2022/10032/)
- [WWDC23 - Explore enhancements to App Intents](https://developer.apple.com/videos/play/wwdc2023/10103/)

---

## Prioridad

**Media-Baja** - Es una funcionalidad "nice to have" pero no crítica para el proyecto.

**Tiempo estimado:** 2-3 horas

**Dependencias:**
- App Groups funcionando (ya está)
- Widget funcionando (ya está)
- Token accesible desde Keychain (ya está)
