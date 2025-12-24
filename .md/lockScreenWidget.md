# Lock Screen Widget - MisMangas

> **Objetivo:** Mostrar el progreso de lectura en la pantalla de bloqueo del iPhone.

---

## Tipos de Lock Screen Widgets

### 1. Accessory Circular (Pequeño redondo)
```
  ┌───┐
  │ 3 │  ← Volumen actual
  │/10│  ← Total
  └───┘
```

### 2. Accessory Rectangular (Rectángulo)
```
  ┌─────────────┐
  │ One Piece   │
  │ Vol. 50/109 │
  │ ████████░░  │  ← Barra de progreso
  └─────────────┘
```

### 3. Accessory Inline (Línea de texto)
```
📚 One Piece - Vol. 50/109
```

---

## Implementación

### 1. Añadir Familias al Widget Existente

En `MisMangas widget/MisMangas_widget.swift`:

```swift
@main
struct MangaWidget: Widget {
    let kind: String = "MangaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MangaWidgetProvider()) { entry in
            MangaWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Mis Mangas")
        .description("Ve tu progreso de lectura")
        .supportedFamilies([
            // Home Screen
            .systemSmall,
            .systemMedium,
            .systemLarge,
            // Lock Screen (iOS 16+)
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}
```

### 2. Crear Vista para Lock Screen

Crear archivo `MisMangas widget/Views/LockScreenWidgetView.swift`:

```swift
import SwiftUI
import WidgetKit

// MARK: - Circular (pequeño redondo)
struct AccessoryCircularView: View {
    let entry: MangaWidgetEntry

    var manga: WidgetManga? {
        entry.widgetData.mangas.first
    }

    var body: some View {
        if let manga = manga {
            Gauge(value: manga.progressPercentage) {
                Image(systemName: "book.fill")
            } currentValueLabel: {
                Text("\(manga.currentVolume)")
                    .font(.system(.title3, design: .rounded))
            }
            .gaugeStyle(.accessoryCircular)
        } else {
            Image(systemName: "books.vertical")
                .font(.title2)
        }
    }
}

// MARK: - Rectangular
struct AccessoryRectangularView: View {
    let entry: MangaWidgetEntry

    var manga: WidgetManga? {
        entry.widgetData.mangas.first
    }

    var body: some View {
        if let manga = manga {
            VStack(alignment: .leading, spacing: 2) {
                Text(manga.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(manga.progressText)
                    .font(.caption)

                ProgressView(value: manga.progressPercentage)
            }
        } else {
            VStack(alignment: .leading) {
                Text("Mis Mangas")
                    .font(.headline)
                Text("Sin lecturas activas")
                    .font(.caption)
            }
        }
    }
}

// MARK: - Inline (una línea)
struct AccessoryInlineView: View {
    let entry: MangaWidgetEntry

    var manga: WidgetManga? {
        entry.widgetData.mangas.first
    }

    var body: some View {
        if let manga = manga {
            Label("\(manga.title) - \(manga.progressText)", systemImage: "book.fill")
        } else {
            Label("Sin lecturas", systemImage: "book")
        }
    }
}
```

### 3. Actualizar MangaWidgetView

En `MisMangas widget/MisMangas_widget.swift`, actualizar la vista principal:

```swift
struct MangaWidgetView: View {
    var entry: MangaWidgetEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        // Home Screen Widgets
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)

        // Lock Screen Widgets
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)

        default:
            Text("No soportado")
        }
    }
}
```

### 4. Previews para Lock Screen

```swift
#Preview("Circular", as: .accessoryCircular) {
    MangaWidget()
} timeline: {
    MangaWidgetEntry(date: .now, widgetData: .placeholder)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    MangaWidget()
} timeline: {
    MangaWidgetEntry(date: .now, widgetData: .placeholder)
}

#Preview("Inline", as: .accessoryInline) {
    MangaWidget()
} timeline: {
    MangaWidgetEntry(date: .now, widgetData: .placeholder)
}
```

---

## Archivos a Modificar/Crear

| Archivo | Acción |
|---------|--------|
| `MisMangas_widget.swift` | Añadir familias Lock Screen |
| `LockScreenWidgetView.swift` | **Crear** - Vistas para Lock Screen |

---

## Pasos de Implementación

### Paso 1: Crear LockScreenWidgetView.swift
```bash
# En MisMangas widget/Views/
touch LockScreenWidgetView.swift
```

### Paso 2: Añadir las 3 vistas
- `AccessoryCircularView` - Gauge circular con progreso
- `AccessoryRectangularView` - Título + progreso + barra
- `AccessoryInlineView` - Una línea de texto

### Paso 3: Actualizar MangaWidgetView
- Añadir casos para las nuevas familias
- Importar las nuevas vistas

### Paso 4: Añadir familias soportadas
- `.accessoryCircular`
- `.accessoryRectangular`
- `.accessoryInline`

### Paso 5: Testing
- Compilar y ejecutar en simulador iOS 16+
- Editar pantalla de bloqueo
- Añadir widget de MisMangas
- Verificar las 3 variantes

---

## Consideraciones de Diseño

### Colores en Lock Screen
- Los widgets de Lock Screen usan **escala de grises** por defecto
- El sistema aplica vibrancy automáticamente
- No uses colores específicos, usa `.primary` y `.secondary`

### Tamaño del Texto
- Mantén el texto **corto y legible**
- Usa `lineLimit(1)` para evitar overflow
- Prioriza información crítica (título, volumen)

### Imágenes
- **No uses AsyncImage** en Lock Screen
- Las imágenes deben ser locales o SF Symbols
- Usa iconos simples de sistema

---

## Checklist

- [ ] Crear `LockScreenWidgetView.swift`
- [ ] Implementar `AccessoryCircularView`
- [ ] Implementar `AccessoryRectangularView`
- [ ] Implementar `AccessoryInlineView`
- [ ] Actualizar `MangaWidgetView` con nuevos casos
- [ ] Añadir familias en `.supportedFamilies`
- [ ] Añadir previews
- [ ] Testing en simulador
- [ ] Testing en dispositivo real

---

## Ejemplo Visual Final

### Pantalla de Bloqueo con Widget
```
┌─────────────────────────────┐
│         12:34               │
│     Lunes 23 Dic            │
│                             │
│  ┌─────────────────────┐    │
│  │ One Piece           │    │  ← Rectangular
│  │ Vol. 50/109         │    │
│  │ ████████████░░░░    │    │
│  └─────────────────────┘    │
│                             │
│        ┌───┐                │
│        │50 │                │  ← Circular
│        │───│                │
│        └───┘                │
│                             │
│  📚 One Piece - Vol. 50/109 │  ← Inline
│                             │
└─────────────────────────────┘
```

---

## Prioridad

**Alta** - Fácil de implementar y añade valor visual significativo.

**Tiempo estimado:** 15-30 minutos

**Dependencias:**
- Widget existente funcionando (ya está)
- iOS 16+ (ya soportado)

---

## Recursos

- [WidgetKit - Lock Screen Widgets](https://developer.apple.com/documentation/widgetkit/creating-lock-screen-widgets-and-watch-complications)
- [WWDC22 - Complications and widgets: Reloaded](https://developer.apple.com/videos/play/wwdc2022/10050/)
