# Versión Deluxe - Ecosistema Apple Completo

> **Objetivo:** Expandir la aplicación al ecosistema completo de Apple con soporte multiplataforma y funcionalidades avanzadas.

---

## 📋 Requisitos según PDF

La versión Deluxe debe incluir:

1. ✅ **Todo de versiones anteriores**
   - Ver [versionBasica.md](versionBasica.md), [versionMedia.md](versionMedia.md) y [versionAvanzada.md](versionAvanzada.md)

2. ⏳ **Soporte para otros dispositivos Apple (al menos uno más)**
   - watchOS
   - macOS (Catalyst o nativo)
   - visionOS (opcional pero impresionante)

3. ⏳ **Widget estático**
   - Mostrar mangas que está leyendo el usuario
   - Progreso de lectura por manga

---

## 📱 Estrategia Multiplataforma

### Opción A: Targets Separados (Recomendado)
```
MisMangas/
├── iOS/           # Target iOS
├── watchOS/       # Target watchOS
├── macOS/         # Target macOS
└── Shared/        # Código compartido
    ├── Models/
    ├── ViewModels/
    └── Network/
```

### Opción B: Swift Package compartido
```
MisMangas/
├── MisMangasCore/     # Swift Package
│   ├── Sources/
│   │   ├── Models/
│   │   ├── Network/
│   │   └── ViewModels/
│   └── Package.swift
├── MisMangas iOS/
├── MisMangas watchOS/
└── MisMangas macOS/
```

**Recomendación:** Opción B para mejor organización y reutilización

---

## ⌚ watchOS App

### Funcionalidades Mínimas

1. **Ver colección del usuario**
2. **Actualizar progreso de lectura**
3. **Ver detalles básicos de manga**

### Estructura watchOS

```swift
// watchOS/ContentView.swift
struct WatchContentView: View {
    @State private var cloudManager: CloudCollectionManager

    var body: some View {
        NavigationStack {
            if cloudManager.cloudCollection.isEmpty {
                ContentUnavailableView("No tienes mangas", systemImage: "book")
            } else {
                List(cloudManager.cloudCollection) { item in
                    NavigationLink(value: item) {
                        WatchMangaRow(item: item)
                    }
                }
            }
            .navigationTitle("Mis Mangas")
            .navigationDestination(for: UserMangaCollection.self) { item in
                WatchMangaDetailView(item: item)
            }
        }
        .task {
            await cloudManager.loadCollection()
        }
    }
}

struct WatchMangaRow: View {
    let item: UserMangaCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.manga.title)
                .font(.headline)
                .lineLimit(2)

            if let reading = item.readingVolume {
                Text("Vol. \(reading)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            if let volumes = item.manga.volumes, let reading = item.readingVolume {
                ProgressView(value: Double(reading), total: Double(volumes))
            }
        }
    }
}

struct WatchMangaDetailView: View {
    let item: UserMangaCollection
    @State private var readingVolume: Int

    init(item: UserMangaCollection) {
        self.item = item
        _readingVolume = State(initialValue: item.readingVolume ?? 0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Portada pequeña
                AsyncImage(url: URL(string: item.manga.mainPicture))
                    .frame(height: 120)

                Text(item.manga.title)
                    .font(.headline)

                // Stepper para actualizar volumen
                Stepper("Vol. \(readingVolume)", value: $readingVolume, in: 0...(item.manga.volumes ?? 100))

                Button("Guardar") {
                    // Actualizar en cloud
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Detalle")
    }
}
```

**Consideraciones watchOS:**
- Usar complicaciones si es posible
- UI simplificada y accesible con Digital Crown
- Soporte para watchOS 10+
- Testing en Apple Watch Series

---

## 💻 macOS App

### Opción A: Mac Catalyst (Más rápido)
1. En Xcode: Target → General → Deployment Info → Mac (Catalyst)
2. Ajustar UI para macOS (menús, toolbar, ventanas)

### Opción B: AppKit nativo (Más control)
- Más trabajo pero mejor experiencia nativa
- Usa AppKit en lugar de SwiftUI para ciertos elementos

### Opción C: SwiftUI nativo macOS ✅ Recomendado
```swift
// macOS/MacAppView.swift
struct MacAppView: View {
    @State private var viewModel = MangaViewModel()
    @State private var selection: Manga?

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(viewModel.mangas, selection: $selection) { manga in
                NavigationLink(value: manga) {
                    Label {
                        VStack(alignment: .leading) {
                            Text(manga.title)
                            Text(manga.titleEnglish ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        AsyncImage(url: URL(string: manga.mainPicture))
                            .frame(width: 40, height: 60)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 300)
        } detail: {
            // Detail pane
            if let manga = selection {
                MacMangaDetailView(manga: manga)
            } else {
                ContentUnavailableView("Selecciona un manga", systemImage: "book")
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

struct MacMangaDetailView: View {
    let manga: Manga

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 20) {
                    // Portada grande
                    AsyncImage(url: URL(string: manga.mainPicture))
                        .frame(width: 300, height: 450)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(manga.title)
                            .font(.largeTitle.bold())

                        Label("\(manga.score, specifier: "%.2f")", systemImage: "star.fill")
                            .foregroundStyle(.orange)

                        if let volumes = manga.volumes {
                            Text("\(volumes) volúmenes")
                        }

                        Divider()

                        // Géneros como tags
                        FlowLayout {
                            ForEach(manga.genres) { genre in
                                Text(genre.genre)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.blue.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Sinopsis
                Text(manga.sypnosis ?? "")
                    .lineSpacing(6)
            }
            .padding(30)
        }
        .toolbar {
            ToolbarItem {
                Button("Añadir a Colección", systemImage: "plus") {
                    // Añadir a colección
                }
            }
        }
    }
}
```

**Características macOS:**
- Menú bar completo
- Toolbar nativo
- Múltiples ventanas
- Drag & drop
- Touch Bar support (si aplicable)
- Keyboard shortcuts

---

## 🧩 Widgets (WidgetKit)

### Widget de Colección

```swift
// Widget/MangaWidget.swift
import WidgetKit
import SwiftUI

struct MangaWidgetEntry: TimelineEntry {
    let date: Date
    let currentlyReading: [MangaProgress]
}

struct MangaProgress {
    let manga: Manga
    let currentVolume: Int
    let totalVolumes: Int

    var progress: Double {
        Double(currentVolume) / Double(totalVolumes)
    }
}

struct MangaWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MangaWidgetEntry {
        MangaWidgetEntry(date: Date(), currentlyReading: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (MangaWidgetEntry) -> Void) {
        let entry = MangaWidgetEntry(date: Date(), currentlyReading: loadCurrentlyReading())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MangaWidgetEntry>) -> Void) {
        let currentDate = Date()
        let entry = MangaWidgetEntry(date: currentDate, currentlyReading: loadCurrentlyReading())

        // Actualizar cada hora
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    private func loadCurrentlyReading() -> [MangaProgress] {
        // Cargar desde UserDefaults compartido o desde API
        // Filtrar solo los que están siendo leídos (readingVolume != nil)
        return []
    }
}

struct MangaWidgetView: View {
    var entry: MangaWidgetEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            Text("Tamaño no soportado")
        }
    }
}

struct SmallWidgetView: View {
    let entry: MangaWidgetEntry

    var body: some View {
        if let first = entry.currentlyReading.first {
            VStack(alignment: .leading, spacing: 8) {
                Text(first.manga.title)
                    .font(.caption.bold())
                    .lineLimit(2)

                ProgressView(value: first.progress)
                    .tint(.orange)

                Text("Vol. \(first.currentVolume)/\(first.totalVolumes)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
        } else {
            VStack {
                Image(systemName: "book")
                Text("No estás leyendo nada")
                    .font(.caption)
            }
            .padding()
        }
    }
}

struct MediumWidgetView: View {
    let entry: MangaWidgetEntry

    var body: some View {
        HStack(spacing: 12) {
            ForEach(entry.currentlyReading.prefix(2), id: \.manga.id) { item in
                VStack(alignment: .leading, spacing: 6) {
                    AsyncImage(url: URL(string: item.manga.mainPicture)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text(item.manga.title)
                        .font(.caption.bold())
                        .lineLimit(1)

                    ProgressView(value: item.progress)
                        .tint(.orange)

                    Text("Vol. \(item.currentVolume)/\(item.totalVolumes)")
                        .font(.caption2)
                }
            }
        }
        .padding()
    }
}

struct LargeWidgetView: View {
    let entry: MangaWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leyendo ahora")
                .font(.headline)

            ForEach(entry.currentlyReading.prefix(4), id: \.manga.id) { item in
                HStack {
                    AsyncImage(url: URL(string: item.manga.mainPicture))
                        .frame(width: 40, height: 60)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.manga.title)
                            .font(.caption.bold())
                            .lineLimit(1)

                        ProgressView(value: item.progress)
                            .tint(.orange)

                        Text("Vol. \(item.currentVolume) de \(item.totalVolumes)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
    }
}

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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
```

**App Groups para compartir datos:**
```swift
// 1. Añadir App Group capability
// Identifier: group.com.yourcompany.mismangas

// 2. Guardar datos compartidos
let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.mismangas")
sharedDefaults?.set(encodedData, forKey: "currentlyReading")

// 3. Leer desde widget
let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.mismangas")
let data = sharedDefaults?.data(forKey: "currentlyReading")
```

---

## 🔄 Handoff entre Dispositivos

```swift
// En MangaDetailView (iOS)
.userActivity("com.yourcompany.mismangas.viewManga") { activity in
    activity.title = manga.title
    activity.isEligibleForHandoff = true
    activity.userInfo = ["mangaId": manga.id]
}

// En macOS/watchOS
.onContinueUserActivity("com.yourcompany.mismangas.viewManga") { activity in
    if let mangaId = activity.userInfo?["mangaId"] as? Int {
        // Navegar al manga
    }
}
```

---

## 🎙️ Siri Shortcuts

```swift
import Intents

// 1. Definir Intent en .intentdefinition
// 2. Implementar handler

class UpdateReadingProgressIntentHandler: NSObject, UpdateReadingProgressIntentHandling {
    func handle(intent: UpdateReadingProgressIntent, completion: @escaping (UpdateReadingProgressIntentResponse) -> Void) {
        guard let mangaId = intent.manga?.identifier,
              let volume = intent.volume as? Int else {
            completion(UpdateReadingProgressIntentResponse(code: .failure, userActivity: nil))
            return
        }

        Task {
            // Actualizar en cloud
            completion(UpdateReadingProgressIntentResponse(code: .success, userActivity: nil))
        }
    }
}

// 3. Donar shortcuts en momentos apropiados
let intent = UpdateReadingProgressIntent()
intent.manga = INObject(identifier: "\(manga.id)", display: manga.title)
intent.volume = currentVolume as NSNumber

let interaction = INInteraction(intent: intent, response: nil)
interaction.donate { error in
    // Handle error
}
```

---

## 📋 Checklist de Entrega - Versión Deluxe

### Multiplataforma
- [ ] watchOS app funcional
- [ ] macOS app funcional (SwiftUI o Catalyst)
- [ ] Código compartido entre plataformas
- [ ] UI adaptada a cada plataforma
- [ ] Testing en todos los dispositivos

### Widget
- [ ] Widget pequeño (systemSmall)
- [ ] Widget mediano (systemMedium)
- [ ] Widget grande (systemLarge)
- [ ] App Groups configurado
- [ ] Datos compartidos correctamente
- [ ] Actualización automática del widget

### Funcionalidades Avanzadas
- [ ] Handoff entre dispositivos
- [ ] Siri Shortcuts básicos
- [ ] Deep linking funcional
- [ ] iCloud sync (opcional con CloudKit)
- [ ] Universal links

### Calidad
- [ ] App funciona en iPhone, iPad, Mac, Watch
- [ ] Widget actualiza correctamente
- [ ] No crashes en ninguna plataforma
- [ ] Performance optimizado
- [ ] Memoria optimizada

---

## 🎯 Orden de Implementación Recomendado

### Semana 1 - Preparación y Shared Code
1. Crear Swift Package para código compartido
2. Migrar Models, ViewModels, Network a package
3. Configurar App Groups
4. Testing de shared code

### Semana 2 - watchOS
1. Crear target watchOS
2. Implementar UI básica
3. Integrar con cloud collection
4. Testing en Watch

### Semana 3 - macOS
1. Crear target macOS
2. Implementar NavigationSplitView
3. Adaptar UI para macOS
4. Añadir menús y toolbar
5. Testing en Mac

### Semana 4 - Widget
1. Crear Widget Extension
2. Implementar Small/Medium/Large views
3. Configurar TimelineProvider
4. Testing del widget

### Semana 5 - Handoff y Shortcuts
1. Implementar Handoff
2. Crear Intents
3. Implementar handlers
4. Donar shortcuts

### Semana 6 - Polish y Testing
1. Testing exhaustivo multiplataforma
2. Performance optimization
3. Bug fixing
4. UI polish en todas las plataformas

---

## 🚀 Funcionalidades Extra (Bonus)

### 1. visionOS Support
- Ventanas 3D con portadas de mangas
- Volumetric UI
- Spatial computing

### 2. Live Activities
- Mostrar progreso de lectura en Dynamic Island
- Actualizar en tiempo real

### 3. CloudKit Sync
- Sincronización automática con iCloud
- Resolución de conflictos
- Soporte offline robusto

### 4. SharePlay
- Leer mangas juntos con amigos
- Ver listas compartidas

### 5. StoreKit
- Funciones premium
- Suscripciones
- In-app purchases

---

## ✨ Criterios de Éxito

La versión Deluxe estará completa cuando:

✅ La app funciona en:
1. iPhone (iOS 17+)
2. iPad con layout adaptativo
3. Apple Watch (watchOS 10+)
4. Mac (macOS 14+)

✅ Widget:
1. Muestra mangas en lectura
2. Actualiza automáticamente
3. Funciona en las 3 tamaños
4. Datos sincronizados correctamente

✅ Experiencia cross-platform:
1. Handoff funciona entre dispositivos
2. Shortcuts funcionan
3. Datos sincronizados en tiempo real
4. UI optimizada para cada plataforma

✅ Calidad:
1. No crashes
2. Performance excelente
3. Memoria optimizada
4. Código mantenible y escalable

---

## 📝 Notas Finales

La versión Deluxe representa la culminación del proyecto MisMangas, transformándolo en una experiencia completa del ecosistema Apple. Cada plataforma debe sentirse nativa mientras mantiene la funcionalidad core sincronizada.

**Recuerda:**
- Prioriza la experiencia de usuario en cada plataforma
- Mantén el código compartido DRY
- Testea exhaustivamente en dispositivos reales
- Optimiza para performance y batería
- Documenta las decisiones de arquitectura multiplataforma

---

**Anterior:** [← Versión Avanzada](versionAvanzada.md)
**Inicio:** [← CLAUDE.md](CLAUDE.md)
