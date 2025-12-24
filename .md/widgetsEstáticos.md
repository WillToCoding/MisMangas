# Plan de Acción: Widgets (WidgetKit)

> **Objetivo:** Implementar un widget estático que muestre los mangas que está leyendo el usuario y por qué volumen va en cada uno de ellos.

---

## 📋 Requisitos del Widget (según PDF)

> "...un widget estático con los mangas que está leyendo el usuario y por donde va en cada uno de ellos."

### Funcionalidades Requeridas
1. Mostrar mangas de la colección del usuario
2. Mostrar el volumen de lectura actual de cada manga
3. Mostrar progreso visual (barra de progreso)
4. Widget estático (actualización periódica, no en tiempo real)

### Información a Mostrar
- Título del manga
- Portada (imagen)
- Volumen actual / Total volúmenes
- Barra de progreso

---

## 🎯 Tipos de Widgets a Implementar

### 1. Widget Pequeño (systemSmall) - 1 Manga
- Portada del manga como fondo
- Título (máx 2 líneas)
- Progreso: "Vol. X/Y"
- Barra de progreso

### 2. Widget Mediano (systemMedium) - 2-3 Mangas
- Layout horizontal
- Portadas pequeñas
- Títulos y progreso compactos

### 3. Widget Grande (systemLarge) - 4-6 Mangas
- Header "Leyendo Ahora"
- Grid/Lista de mangas
- Más detalle por manga

### 4. Lock Screen Widget (iOS 16+)
- Accesory rectangular: Título + progreso
- Accessory circular: Gauge de progreso

---

## 🏗️ Arquitectura del Widget

### Estructura de Carpetas
```
MisMangas/
├── MisMangas/                    # App iOS (ya existe)
├── MisMangasWidget/              # NUEVO - Widget Extension
│   ├── MisMangasWidget.swift     # Widget principal
│   ├── MisMangasWidgetBundle.swift
│   ├── Provider/
│   │   └── MangaWidgetProvider.swift
│   ├── Views/
│   │   ├── SmallWidgetView.swift
│   │   ├── MediumWidgetView.swift
│   │   ├── LargeWidgetView.swift
│   │   └── LockScreenWidgetView.swift
│   ├── Model/
│   │   └── WidgetManga.swift
│   └── Assets.xcassets/
└── Shared/
    └── SharedDataManager.swift   # NUEVO - Compartir datos App <-> Widget
```

### Flujo de Datos
```
┌─────────────────────────────────────────────────────────┐
│                    App Principal (iOS)                   │
│                                                          │
│  CloudCollectionViewModel                               │
│         │                                                │
│         ▼                                                │
│  SharedDataManager.updateWidgetFromCollection()         │
│         │                                                │
│         ▼                                                │
│  UserDefaults (App Group)  ◄─────────────────────────┐  │
│         │                                             │  │
└─────────┼─────────────────────────────────────────────┼──┘
          │                                             │
          ▼                                             │
┌─────────────────────────────────────────────────────────┐
│                    Widget Extension                      │
│                                                          │
│  MangaWidgetProvider                                    │
│         │                                                │
│         ▼                                                │
│  SharedDataManager.loadWidgetData()                     │
│         │                                                │
│         ▼                                                │
│  WidgetViews (Small/Medium/Large)                       │
└─────────────────────────────────────────────────────────┘
```

---

## 📝 Plan de Implementación Paso a Paso

### PASO 1: Crear Widget Extension Target

**Acciones:**
1. En Xcode: File → New → Target
2. Seleccionar: **Widget Extension**
3. Nombre: `MisMangasWidget`
4. ✅ Include Configuration App Intent
5. Click "Finish"

**Resultado esperado:**
- Nuevo target `MisMangasWidget`
- Archivos base generados automáticamente

---

### PASO 2: Configurar App Groups

**¿Por qué?** Para compartir datos entre la app principal y el widget.

**App Group existente:** `group.com.murtidev.MisMangas`

**Acciones iOS Target:**
1. Seleccionar target `MisMangas` (iOS)
2. Signing & Capabilities → + Capability
3. Agregar **App Groups** (si no existe)
4. Crear/seleccionar: `group.com.murtidev.MisMangas`

**Acciones Widget Target:**
1. Seleccionar target `MisMangasWidget`
2. Signing & Capabilities → + Capability
3. Agregar **App Groups**
4. Seleccionar: `group.com.murtidev.MisMangas`

---

### PASO 3: Crear Modelo para Widget

**Archivo:** `MisMangasWidget/Model/WidgetManga.swift`

```swift
//
//  WidgetManga.swift
//  MisMangasWidget
//

import Foundation

/// Modelo simplificado de manga para el widget
/// Debe ser Codable para guardarse en App Group
struct WidgetManga: Codable, Identifiable, Sendable {
    let id: Int
    let title: String
    let mainPicture: String
    let currentVolume: Int
    let totalVolumes: Int?
    let score: Double

    var progressText: String {
        if let total = totalVolumes {
            return "Vol. \(currentVolume)/\(total)"
        }
        return "Vol. \(currentVolume)"
    }

    var progressPercentage: Double {
        guard let total = totalVolumes, total > 0 else { return 0 }
        return Double(currentVolume) / Double(total)
    }

    var imageURL: URL? {
        URL(string: mainPicture)
    }
}

/// Datos compartidos entre App y Widget
struct WidgetData: Codable, Sendable {
    let mangas: [WidgetManga]
    let lastUpdated: Date
    let userEmail: String?

    static let empty = WidgetData(mangas: [], lastUpdated: Date(), userEmail: nil)

    /// Datos de ejemplo para placeholder/preview
    static let placeholder = WidgetData(
        mangas: [
            WidgetManga(
                id: 42,
                title: "Dragon Ball",
                mainPicture: "https://cdn.myanimelist.net/images/manga/1/267793l.jpg",
                currentVolume: 15,
                totalVolumes: 42,
                score: 8.41
            ),
            WidgetManga(
                id: 21,
                title: "One Piece",
                mainPicture: "https://cdn.myanimelist.net/images/manga/2/253146l.jpg",
                currentVolume: 50,
                totalVolumes: 109,
                score: 9.21
            ),
            WidgetManga(
                id: 11,
                title: "Naruto",
                mainPicture: "https://cdn.myanimelist.net/images/manga/3/249658l.jpg",
                currentVolume: 30,
                totalVolumes: 72,
                score: 8.07
            ),
            WidgetManga(
                id: 13,
                title: "One Punch-Man",
                mainPicture: "https://cdn.myanimelist.net/images/manga/3/80661l.jpg",
                currentVolume: 12,
                totalVolumes: 29,
                score: 8.69
            )
        ],
        lastUpdated: Date(),
        userEmail: "usuario@example.com"
    )
}
```

---

### PASO 4: Crear SharedDataManager

**Archivo:** `MisMangas/Storage/SharedDataManager.swift`

> **IMPORTANTE:** Este archivo debe compartirse con el widget (Target Membership)

```swift
//
//  SharedDataManager.swift
//  MisMangas
//

import Foundation
import WidgetKit

/// Gestiona los datos compartidos entre App y Widget via App Groups
@MainActor
final class SharedDataManager: Sendable {
    static let shared = SharedDataManager()

    private let appGroupID = "group.com.murtidev.MisMangas"
    private let widgetDataKey = "widgetMangaData"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    private init() {}

    // MARK: - Save Data (desde la App)

    /// Guarda los mangas de la colección para el widget
    func saveWidgetData(_ data: WidgetData) {
        guard let defaults = sharedDefaults else {
            print("[SharedDataManager] Error: No se pudo acceder a App Group")
            return
        }

        do {
            let encoded = try JSONEncoder().encode(data)
            defaults.set(encoded, forKey: widgetDataKey)
            print("[SharedDataManager] Widget data guardada: \(data.mangas.count) mangas")
        } catch {
            print("[SharedDataManager] Error guardando widget data: \(error)")
        }
    }

    /// Convierte UserMangaCollection a WidgetManga y guarda
    func updateWidgetFromCollection(_ collection: [UserMangaCollection], userEmail: String?) {
        // Solo incluir mangas con progreso de lectura (readingVolume != nil)
        let widgetMangas = collection.compactMap { item -> WidgetManga? in
            guard let readingVolume = item.readingVolume else { return nil }

            return WidgetManga(
                id: item.manga.id,
                title: item.manga.title,
                mainPicture: item.manga.mainPicture.replacingOccurrences(of: "\"", with: ""),
                currentVolume: readingVolume,
                totalVolumes: item.manga.volumes,
                score: item.manga.score
            )
        }

        // Ordenar por progreso (los más avanzados primero) o por score
        let sortedMangas = widgetMangas.sorted { manga1, manga2 in
            // Priorizar los que están siendo leídos activamente
            manga1.progressPercentage > manga2.progressPercentage
        }

        // Limitar a los primeros 10 para el widget
        let limitedMangas = Array(sortedMangas.prefix(10))

        let widgetData = WidgetData(
            mangas: limitedMangas,
            lastUpdated: Date(),
            userEmail: userEmail
        )

        saveWidgetData(widgetData)

        // Recargar los widgets
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Load Data (desde el Widget)

    /// Carga los datos del widget
    nonisolated func loadWidgetData() -> WidgetData {
        guard let defaults = UserDefaults(suiteName: "group.com.murtidev.MisMangas"),
              let data = defaults.data(forKey: "widgetMangaData") else {
            return .empty
        }

        do {
            return try JSONDecoder().decode(WidgetData.self, from: data)
        } catch {
            print("[SharedDataManager] Error cargando widget data: \(error)")
            return .empty
        }
    }

    // MARK: - Clear Data

    /// Limpia los datos del widget (al hacer logout)
    func clearWidgetData() {
        sharedDefaults?.removeObject(forKey: widgetDataKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
```

---

### PASO 5: Widget Provider

**Archivo:** `MisMangasWidget/Provider/MangaWidgetProvider.swift`

```swift
//
//  MangaWidgetProvider.swift
//  MisMangasWidget
//

import WidgetKit
import SwiftUI

/// Entry que representa un snapshot del widget
struct MangaWidgetEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetData
}

/// Provider que genera el timeline del widget
struct MangaWidgetProvider: TimelineProvider {
    typealias Entry = MangaWidgetEntry

    // Placeholder mientras carga (diseño estático)
    func placeholder(in context: Context) -> MangaWidgetEntry {
        MangaWidgetEntry(
            date: Date(),
            widgetData: .placeholder
        )
    }

    // Snapshot para la galería de widgets
    func getSnapshot(in context: Context, completion: @escaping (MangaWidgetEntry) -> Void) {
        let widgetData = SharedDataManager.shared.loadWidgetData()
        let entry = MangaWidgetEntry(
            date: Date(),
            widgetData: widgetData.mangas.isEmpty ? .placeholder : widgetData
        )
        completion(entry)
    }

    // Timeline con actualizaciones
    func getTimeline(in context: Context, completion: @escaping (Timeline<MangaWidgetEntry>) -> Void) {
        let widgetData = SharedDataManager.shared.loadWidgetData()

        let entry = MangaWidgetEntry(
            date: Date(),
            widgetData: widgetData
        )

        // Actualizar cada 30 minutos
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
```

---

### PASO 6: Vistas del Widget

**Archivo:** `MisMangasWidget/Views/SmallWidgetView.swift`

```swift
//
//  SmallWidgetView.swift
//  MisMangasWidget
//

import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: MangaWidgetEntry

    var manga: WidgetManga? {
        entry.widgetData.mangas.first
    }

    var body: some View {
        if let manga = manga {
            ZStack {
                // Fondo con imagen
                AsyncImage(url: manga.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }

                // Overlay oscuro
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Contenido
                VStack(alignment: .leading) {
                    Spacer()

                    Text(manga.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .shadow(radius: 2)

                    HStack {
                        Image(systemName: "book.fill")
                            .font(.caption)
                        Text(manga.progressText)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white.opacity(0.9))

                    // Barra de progreso
                    ProgressView(value: manga.progressPercentage)
                        .tint(.white)
                        .background(.white.opacity(0.3))
                }
                .padding()
            }
        } else {
            // Estado vacío
            VStack(spacing: 8) {
                Image(systemName: "books.vertical")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Sin mangas")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Añade mangas a tu colección")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}
```

**Archivo:** `MisMangasWidget/Views/MediumWidgetView.swift`

```swift
//
//  MediumWidgetView.swift
//  MisMangasWidget
//

import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: MangaWidgetEntry

    var mangas: [WidgetManga] {
        Array(entry.widgetData.mangas.prefix(3))
    }

    var body: some View {
        if mangas.isEmpty {
            emptyState
        } else {
            HStack(spacing: 12) {
                ForEach(mangas) { manga in
                    MangaCardView(manga: manga)
                }
            }
            .padding()
        }
    }

    private var emptyState: some View {
        HStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("MisMangas")
                    .font(.headline)
                Text("Abre la app para ver tu colección")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

struct MangaCardView: View {
    let manga: WidgetManga

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Portada
            AsyncImage(url: manga.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.3))
                        .overlay {
                            Image(systemName: "book.closed")
                                .foregroundStyle(.gray)
                        }
                }
            }
            .frame(height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Info
            Text(manga.title)
                .font(.caption2)
                .fontWeight(.semibold)
                .lineLimit(1)

            Text(manga.progressText)
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Progreso
            ProgressView(value: manga.progressPercentage)
                .tint(.accentColor)
        }
    }
}
```

**Archivo:** `MisMangasWidget/Views/LargeWidgetView.swift`

```swift
//
//  LargeWidgetView.swift
//  MisMangasWidget
//

import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let entry: MangaWidgetEntry

    var mangas: [WidgetManga] {
        Array(entry.widgetData.mangas.prefix(6))
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "books.vertical.fill")
                    .foregroundStyle(.accentColor)
                Text("Leyendo Ahora")
                    .font(.headline)
                Spacer()
                if let email = entry.widgetData.userEmail {
                    Text(email)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if mangas.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                // Grid de mangas
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(mangas) { manga in
                        LargeMangaCard(manga: manga)
                    }
                }
            }
        }
        .padding()
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No hay mangas en lectura")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Abre MisMangas para añadir mangas a tu colección")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LargeMangaCard: View {
    let manga: WidgetManga

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Portada
            AsyncImage(url: manga.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.3))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.gray)
                        }
                }
            }
            .frame(height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Título
            Text(manga.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            // Progreso
            HStack(spacing: 4) {
                Image(systemName: "book.fill")
                    .font(.system(size: 8))
                Text(manga.progressText)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)

            ProgressView(value: manga.progressPercentage)
                .tint(.accentColor)
        }
    }
}
```

**Archivo:** `MisMangasWidget/Views/LockScreenWidgetView.swift`

```swift
//
//  LockScreenWidgetView.swift
//  MisMangasWidget
//

import SwiftUI
import WidgetKit

// Rectangular Lock Screen Widget
struct RectangularLockScreenView: View {
    let entry: MangaWidgetEntry

    var manga: WidgetManga? {
        entry.widgetData.mangas.first
    }

    var body: some View {
        if let manga = manga {
            HStack(spacing: 8) {
                // Icono
                Image(systemName: "book.fill")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(manga.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(manga.progressText)
                        .font(.caption2)

                    ProgressView(value: manga.progressPercentage)
                }
            }
        } else {
            HStack {
                Image(systemName: "books.vertical")
                Text("Sin mangas")
                    .font(.caption)
            }
        }
    }
}

// Circular Lock Screen Widget
struct CircularLockScreenView: View {
    let entry: MangaWidgetEntry

    var manga: WidgetManga? {
        entry.widgetData.mangas.first
    }

    var body: some View {
        if let manga = manga {
            Gauge(value: manga.progressPercentage) {
                Image(systemName: "book.fill")
            }
            .gaugeStyle(.accessoryCircular)
        } else {
            Image(systemName: "books.vertical")
        }
    }
}

// Inline Lock Screen Widget
struct InlineLockScreenView: View {
    let entry: MangaWidgetEntry

    var manga: WidgetManga? {
        entry.widgetData.mangas.first
    }

    var body: some View {
        if let manga = manga {
            Text("\(manga.title) - \(manga.progressText)")
        } else {
            Text("MisMangas")
        }
    }
}
```

---

### PASO 7: Widget Principal

**Archivo:** `MisMangasWidget/MisMangasWidget.swift`

```swift
//
//  MisMangasWidget.swift
//  MisMangasWidget
//

import WidgetKit
import SwiftUI

// MARK: - Home Screen Widget

struct MisMangasWidget: Widget {
    let kind: String = "MisMangasWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MangaWidgetProvider()) { entry in
            MisMangasWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("MisMangas")
        .description("Ve el progreso de tus mangas en lectura")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct MisMangasWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: MangaWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Lock Screen Widgets (iOS 16+)

struct MisMangasLockScreenWidget: Widget {
    let kind: String = "MisMangasLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MangaWidgetProvider()) { entry in
            LockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("MisMangas")
        .description("Progreso de lectura en pantalla de bloqueo")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline
        ])
    }
}

struct LockScreenWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: MangaWidgetEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            RectangularLockScreenView(entry: entry)
        case .accessoryCircular:
            CircularLockScreenView(entry: entry)
        case .accessoryInline:
            InlineLockScreenView(entry: entry)
        default:
            RectangularLockScreenView(entry: entry)
        }
    }
}
```

**Archivo:** `MisMangasWidget/MisMangasWidgetBundle.swift`

```swift
//
//  MisMangasWidgetBundle.swift
//  MisMangasWidget
//

import WidgetKit
import SwiftUI

@main
struct MisMangasWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Widget principal para Home Screen
        MisMangasWidget()

        // Widget para Lock Screen (iOS 16+)
        MisMangasLockScreenWidget()
    }
}
```

---

### PASO 8: Integrar en CloudCollectionViewModel

**Modificar:** `MisMangas/ViewModel/CloudCollectionViewModel.swift`

Añadir al final de `loadCollection()`:

```swift
// MARK: - Load Collection

func loadCollection() async {
    guard let token = authVM.authToken else {
        errorMessage = "No estás autenticado"
        return
    }

    isLoading = true
    errorMessage = nil

    do {
        cloudCollection = try await repository.getUserCollection(token: token)
        print("Colección cloud cargada: \(cloudCollection.count) mangas")

        // NUEVO: Actualizar datos del widget
        SharedDataManager.shared.updateWidgetFromCollection(
            cloudCollection,
            userEmail: authVM.userEmail
        )

    } catch {
        if isUnauthorizedError(error) {
            authVM.handleSessionExpired()
        } else {
            errorMessage = "Error al cargar colección: \(error.localizedDescription)"
            print("Error cargando colección cloud: \(error)")
        }
    }

    isLoading = false
}
```

También añadir al final de `addToCollection()`:

```swift
// Después de añadir manga, actualizar widget
SharedDataManager.shared.updateWidgetFromCollection(
    cloudCollection,
    userEmail: authVM.userEmail
)
```

---

### PASO 9: Integrar en AuthViewModel

**Modificar:** `MisMangas/ViewModel/AuthViewModel.swift`

Añadir en `logout()`:

```swift
func logout() {
    keychain.clearAll()
    authToken = nil
    userEmail = nil
    isAuthenticated = false
    errorMessage = nil
    showSessionExpiredAlert = false

    // NUEVO: Limpiar datos del widget
    SharedDataManager.shared.clearWidgetData()

    print("Sesión cerrada")
}
```

---

### PASO 10: Compartir Archivos con Widget

**Archivos a compartir (Target Membership):**

Seleccionar cada archivo → Inspector (⌥⌘1) → Target Membership → Marcar `MisMangasWidget`:

1. `SharedDataManager.swift`
2. `WidgetManga.swift` (si está en carpeta compartida)

**Nota:** Los archivos de Model (como `UserMangaCollection`) NO necesitan compartirse porque `SharedDataManager` convierte los datos a `WidgetManga` antes de guardar.

---

## ✅ Checklist de Implementación

### Setup Inicial
- [ ] Crear Widget Extension target en Xcode
- [ ] Configurar App Groups en iOS target
- [ ] Configurar App Groups en Widget target
- [ ] Verificar que ambos usan `group.com.murtidev.MisMangas`

### Modelos y Data Manager
- [ ] Crear `WidgetManga.swift`
- [ ] Crear `WidgetData.swift`
- [ ] Crear `SharedDataManager.swift`
- [ ] Compartir `SharedDataManager` con widget target

### Widget Views
- [ ] `SmallWidgetView.swift` (1 manga)
- [ ] `MediumWidgetView.swift` (2-3 mangas)
- [ ] `LargeWidgetView.swift` (4-6 mangas)
- [ ] `LockScreenWidgetView.swift` (iOS 16+)

### Provider y Configuration
- [ ] `MangaWidgetProvider.swift`
- [ ] `MisMangasWidget.swift`
- [ ] `MisMangasWidgetBundle.swift`

### Integración con App Principal
- [ ] Modificar `CloudCollectionViewModel.loadCollection()`
- [ ] Modificar `CloudCollectionViewModel.addToCollection()`
- [ ] Modificar `AuthViewModel.logout()`
- [ ] Import WidgetKit donde sea necesario

### Testing
- [ ] Probar widget pequeño
- [ ] Probar widget mediano
- [ ] Probar widget grande
- [ ] Probar widgets en Lock Screen
- [ ] Probar estado vacío (sin mangas)
- [ ] Probar actualización de datos al añadir/modificar manga
- [ ] Probar limpieza de datos al hacer logout
- [ ] Probar placeholder en galería de widgets

---

## 🎯 Resultado Final

Al completar este plan tendrás:

✅ Widget estático mostrando mangas en lectura
✅ Progreso de lectura visible (Vol. X/Y)
✅ Portadas de los mangas
✅ 3 tamaños de widget (small, medium, large)
✅ Widgets para Lock Screen (iOS 16+)
✅ Sincronización automática con la colección
✅ Estado vacío manejado elegantemente

---

## 📱 Plataformas Soportadas

| Plataforma | Home Screen | Lock Screen | StandBy |
|------------|-------------|-------------|---------|
| iOS 17+    | ✅          | ✅          | ✅      |
| iPadOS 17+ | ✅          | ✅          | -       |
| macOS 14+  | ✅ (Notification Center) | - | - |

---

## 🔍 Notas Importantes

### Limitaciones de Widgets
- **No son interactivos en tiempo real** - Solo actualizan via timeline
- **Sin networking directo** - Deben usar datos guardados en App Group
- **Memoria limitada** - Mantener imágenes pequeñas
- **Sin estado persistente** - Todo debe cargarse desde App Group

### Buenas Prácticas
- Usar `containerBackground` para iOS 17+
- Implementar placeholder atractivo para galería
- Manejar estado vacío elegantemente
- Limitar cantidad de datos guardados (max 10 mangas)
- Actualizar widgets solo cuando sea necesario
- No abusar de `WidgetCenter.shared.reloadAllTimelines()`

### Frecuencia de Actualización
- Timeline policy: `.after(30 minutes)` - Actualización cada 30 min
- Actualización manual con `WidgetCenter.shared.reloadAllTimelines()` al:
  - Añadir manga a colección
  - Actualizar progreso de lectura
  - Hacer logout

### Debugging
- Usar Canvas Preview para probar vistas
- Verificar que App Group ID coincide exactamente
- Revisar Console.app para logs del widget
- Si no aparece, reiniciar Springboard: `killall SpringBoard`

---

## 📚 Referencias

- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [Creating a Widget Extension](https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension)
- [Making a Configurable Widget](https://developer.apple.com/documentation/widgetkit/making-a-configurable-widget)
- [WWDC23 - Bring widgets to new places](https://developer.apple.com/videos/play/wwdc2023/10027/)

---

**Siguiente paso:** ¿Empezamos con el PASO 1 (Crear Widget Extension)?
