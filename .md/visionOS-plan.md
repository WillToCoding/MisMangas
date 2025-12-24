# Plan de Acción: visionOS App

> **Objetivo:** Implementar una app para Apple Vision Pro que muestre la colección de mangas en una experiencia espacial inmersiva.

---

## 📋 Requisitos de la App visionOS

### Funcionalidades Mínimas
1. Ver colección de mangas en el espacio
2. Navegar por la colección con gestos y mirada
3. Ver detalles de cada manga en ventanas flotantes
4. Actualizar volumen de lectura
5. Experiencia inmersiva opcional

### Características visionOS
- UI espacial con ventanas 3D
- Navegación con gestos y mirada (Eye tracking)
- Ornaments (controles flotantes)
- Espacios inmersivos opcionales
- Sin SwiftData (solo red/UserDefaults)

---

## 🏗️ Arquitectura del Proyecto

### Estructura de Carpetas
```
MisMangas/
├── MisMangas/              # App iOS (ya existe)
├── MisMangas visionOS/     # NUEVO - App visionOS
│   ├── MisMangasApp.swift
│   ├── ContentView.swift
│   ├── Views/
│   │   ├── VisionCollectionView.swift
│   │   ├── VisionMangaCard.swift
│   │   ├── VisionMangaDetailView.swift
│   │   └── VisionImmersiveView.swift (opcional)
│   └── Assets.xcassets
└── Shared/                 # Código compartido
    ├── Models/             # Ya existe - reutilizar
    ├── ViewModels/         # Ya existe - reutilizar
    └── Network/            # Ya existe - reutilizar
```

---

## 📝 Plan de Implementación Paso a Paso

### PASO 1: Crear visionOS Target

**Acciones:**
1. En Xcode: File → New → Target
2. Seleccionar: **visionOS** → **App**
3. Nombre: `MisMangas visionOS`
4. Language: Swift
5. Interface: SwiftUI
6. Initial Scene: Window
7. Click "Finish"

**Resultado esperado:**
- Nuevo folder `MisMangas visionOS` en el proyecto
- Nuevo scheme `MisMangas visionOS`

---

### PASO 2: Configurar App Groups

**¿Por qué?** Para compartir el token de autenticación entre plataformas.

**Acciones visionOS:**
1. Seleccionar target `MisMangas visionOS`
2. Signing & Capabilities → + Capability
3. Agregar **App Groups**
4. Seleccionar: `group.com.mismangas.shared` (ya existe)

---

### PASO 3: Compartir Código Existente

**Archivos a compartir con visionOS:**

1. **Models**:
   - `ModelDTO.swift`
   - `AuthError.swift`
   - NO incluir `Model.swift` (SwiftData)

2. **Network**:
   - `NetworkRepository.swift`
   - `URL.swift`

3. **Storage**:
   - `KeychainHelper.swift`

4. **ViewModels**:
   - `AuthViewModel.swift`
   - `CloudCollectionViewModel.swift`

**Cómo compartir:**
1. Seleccionar archivo en navegador
2. Inspector de archivos (⌥⌘1)
3. Target Membership → Marcar `MisMangas visionOS`

---

### PASO 4: App Principal visionOS

**Archivo:** `MisMangas visionOS/MisMangasApp.swift`

```swift
import SwiftUI

@main
struct MisMangas_visionOS_App: App {
    @State private var authVM: AuthViewModel
    @State private var cloudVM: CloudCollectionViewModel

    init() {
        let auth = AuthViewModel()
        _authVM = State(initialValue: auth)
        _cloudVM = State(initialValue: CloudCollectionViewModel(authVM: auth))
    }

    var body: some Scene {
        // Ventana principal
        WindowGroup {
            VisionRootView()
                .environment(authVM)
                .environment(cloudVM)
        }
        .defaultSize(width: 1200, height: 800)

        // Espacio inmersivo opcional
        ImmersiveSpace(id: "ImmersiveMangaSpace") {
            VisionImmersiveView()
                .environment(cloudVM)
        }
    }
}
```

---

### PASO 5: Vista Principal (Root)

**Archivo:** `MisMangas visionOS/Views/VisionRootView.swift`

```swift
import SwiftUI

struct VisionRootView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @State private var showImmersive = false

    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(alignment: .leading, spacing: 20) {
                if authVM.isAuthenticated {
                    Label(authVM.userEmail ?? "Usuario", systemImage: "person.circle.fill")
                        .font(.headline)
                } else {
                    Label("No autenticado", systemImage: "person.circle")
                        .foregroundStyle(.secondary)
                }

                Divider()

                Button {
                    Task {
                        if showImmersive {
                            await dismissImmersiveSpace()
                        } else {
                            await openImmersiveSpace(id: "ImmersiveMangaSpace")
                        }
                        showImmersive.toggle()
                    }
                } label: {
                    Label(
                        showImmersive ? "Salir Inmersivo" : "Modo Inmersivo",
                        systemImage: showImmersive ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
                    )
                }

                Spacer()
            }
            .padding()
            .frame(width: 250)
            .navigationTitle("MisMangas")
        } detail: {
            // Vista principal
            if !authVM.isAuthenticated {
                VisionLoginPromptView()
            } else if cloudVM.isLoading && cloudVM.cloudCollection.isEmpty {
                ProgressView("Cargando colección...")
                    .font(.title)
            } else if cloudVM.cloudCollection.isEmpty {
                ContentUnavailableView(
                    "Sin Mangas",
                    systemImage: "books.vertical",
                    description: Text("Inicia sesión desde iPhone/iPad para ver tu colección")
                )
            } else {
                VisionCollectionView()
            }
        }
        .task {
            if authVM.isAuthenticated {
                await cloudVM.loadCollection()
            }
        }
    }
}

struct VisionLoginPromptView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "vision.pro")
                .font(.system(size: 100))
                .foregroundStyle(.blue)

            Text("Bienvenido a MisMangas")
                .font(.largeTitle.bold())

            Text("Inicia sesión desde tu iPhone o iPad para acceder a tu colección")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
        }
        .padding(60)
    }
}
```

---

### PASO 6: Vista de Colección (Grid 3D)

**Archivo:** `MisMangas visionOS/Views/VisionCollectionView.swift`

```swift
import SwiftUI

struct VisionCollectionView: View {
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.scenePhase) private var scenePhase

    // Grid 3x3 para aprovechar espacio visionOS
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 40)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 40) {
                ForEach(cloudVM.cloudCollection) { item in
                    NavigationLink(value: item.id) {
                        VisionMangaCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(60)
        }
        .navigationTitle("Mi Colección")
        .navigationDestination(for: String.self) { itemId in
            if let item = cloudVM.cloudCollection.first(where: { $0.id == itemId }) {
                VisionMangaDetailView(item: item)
            }
        }
        .refreshable {
            await cloudVM.loadCollection()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                Task {
                    await cloudVM.loadCollection()
                }
            }
        }
        .ornament(attachmentAnchor: .scene(.top)) {
            if cloudVM.isLoading {
                ProgressView()
                    .padding()
                    .glassBackgroundEffect()
            }
        }
    }
}
```

---

### PASO 7: Card de Manga (3D Effect)

**Archivo:** `MisMangas visionOS/Views/VisionMangaCard.swift`

```swift
import SwiftUI

struct VisionMangaCard: View {
    let item: UserMangaCollection

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Portada con efecto 3D
            AsyncImage(url: URL(string: item.manga.mainPicture.replacingOccurrences(of: "\"", with: ""))) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .overlay {
                            ProgressView()
                        }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.gray)
                        }
                @unknown default:
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                }
            }
            .frame(width: 300, height: 450)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: isHovered ? 20 : 10)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isHovered)

            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(item.manga.title)
                    .font(.title2.bold())
                    .lineLimit(2)

                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.2f", item.manga.score))
                        .font(.headline)
                }

                // Progreso
                if let total = item.manga.volumes {
                    let reading = item.readingVolume ?? 1
                    HStack {
                        Text("Vol. \(reading)/\(total)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        ProgressView(value: Double(reading), total: Double(total))
                            .frame(width: 100)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(width: 300)
        .padding()
        .glassBackgroundEffect()
        .hoverEffect()
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
```

---

### PASO 8: Vista de Detalle

**Archivo:** `MisMangas visionOS/Views/VisionMangaDetailView.swift`

```swift
import SwiftUI

struct VisionMangaDetailView: View {
    let item: UserMangaCollection

    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.dismiss) private var dismiss

    @State private var currentVolume: Int
    @State private var isSaving = false

    init(item: UserMangaCollection) {
        self.item = item
        _currentVolume = State(initialValue: item.readingVolume ?? 1)
    }

    var updatedItem: UserMangaCollection {
        cloudVM.cloudCollection.first(where: { $0.id == item.id }) ?? item
    }

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 60) {
                // Portada grande
                AsyncImage(url: URL(string: updatedItem.manga.mainPicture.replacingOccurrences(of: "\"", with: ""))) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 400, height: 600)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 30)

                // Información
                VStack(alignment: .leading, spacing: 30) {
                    Text(updatedItem.manga.title)
                        .font(.system(size: 48, weight: .bold))

                    HStack(spacing: 40) {
                        VStack(alignment: .leading) {
                            Text("Puntuación")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text(String(format: "%.2f", updatedItem.manga.score))
                                    .font(.title.bold())
                            }
                        }

                        if let volumes = updatedItem.manga.volumes {
                            VStack(alignment: .leading) {
                                Text("Volúmenes")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(volumes)")
                                    .font(.title.bold())
                            }
                        }
                    }

                    Divider()

                    // Control de progreso
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Tu Progreso")
                            .font(.title2.bold())

                        HStack {
                            Button {
                                if currentVolume > 1 {
                                    currentVolume -= 1
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                            }
                            .disabled(currentVolume <= 1)

                            Text("Volumen \(currentVolume)")
                                .font(.title.bold())
                                .frame(minWidth: 200)

                            Button {
                                if let max = updatedItem.manga.volumes, currentVolume < max {
                                    currentVolume += 1
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                            }
                            .disabled(currentVolume >= (updatedItem.manga.volumes ?? 999))
                        }

                        if let total = updatedItem.manga.volumes {
                            ProgressView(value: Double(currentVolume), total: Double(total))
                                .frame(maxWidth: 400)
                        }
                    }

                    Divider()

                    Button {
                        Task {
                            await saveProgress()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Label("Guardar Progreso", systemImage: "checkmark.circle.fill")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isSaving || currentVolume == updatedItem.readingVolume)
                }
                .frame(maxWidth: 600)
            }
            .padding(60)
        }
        .navigationTitle(updatedItem.manga.title)
    }

    private func saveProgress() async {
        isSaving = true

        do {
            try await cloudVM.addToCollection(
                manga: updatedItem.manga,
                volumesOwned: updatedItem.volumesOwned,
                readingVolume: currentVolume,
                completeCollection: updatedItem.completeCollection
            )

            try? await Task.sleep(for: .milliseconds(500))
            dismiss()
        } catch {
            print("Error guardando progreso: \(error)")
        }

        isSaving = false
    }
}
```

---

### PASO 9 (OPCIONAL): Vista Inmersiva

**Archivo:** `MisMangas visionOS/Views/VisionImmersiveView.swift`

```swift
import SwiftUI
import RealityKit

struct VisionImmersiveView: View {
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    var body: some View {
        RealityView { content in
            // Crear una galería circular de mangas en 3D
            let radius: Float = 3.0
            let count = min(cloudVM.cloudCollection.count, 12)

            for (index, manga) in cloudVM.cloudCollection.prefix(count).enumerated() {
                let angle = Float(index) * (360.0 / Float(count)) * .pi / 180.0
                let x = radius * cos(angle)
                let z = radius * sin(angle)

                // Crear entidad para cada manga
                let entity = ModelEntity(
                    mesh: .generateBox(width: 0.3, height: 0.45, depth: 0.02),
                    materials: [SimpleMaterial(color: .white, isMetallic: false)]
                )

                entity.position = SIMD3(x: x, y: 1.5, z: z)
                entity.look(at: SIMD3(x: 0, y: 1.5, z: 0), from: entity.position, relativeTo: nil)

                content.add(entity)
            }
        }
    }
}
```

---

## ✅ Checklist de Implementación

### Setup Inicial
- [ ] Crear visionOS target en Xcode
- [ ] Configurar App Groups (visionOS)
- [ ] Compartir archivos de Models con visionOS
- [ ] Compartir Network layer con visionOS
- [ ] Compartir KeychainHelper con visionOS
- [ ] Compartir ViewModels con visionOS

### Vistas visionOS
- [ ] Crear MisMangasApp.swift
- [ ] Crear VisionRootView.swift
- [ ] Crear VisionLoginPromptView
- [ ] Crear VisionCollectionView.swift
- [ ] Crear VisionMangaCard.swift
- [ ] Crear VisionMangaDetailView.swift
- [ ] (Opcional) Crear VisionImmersiveView.swift

### Funcionalidades
- [ ] Cargar colección desde cloud
- [ ] Mostrar grid de mangas en espacio
- [ ] Navegar a detalle
- [ ] Actualizar volumen de lectura
- [ ] Sincronizar con servidor
- [ ] Hover effects
- [ ] (Opcional) Modo inmersivo

### Testing
- [ ] Probar en simulador visionOS
- [ ] Verificar compartición de token
- [ ] Probar navegación con gestos/mirada
- [ ] Verificar sincronización

---

## 🎯 Resultado Final

Al completar este plan tendrás:

✅ App visionOS funcional
✅ Experiencia espacial moderna
✅ Navegación con gestos y mirada
✅ Ver y actualizar colección
✅ Compartir autenticación entre plataformas
✅ (Opcional) Modo inmersivo 3D

---

## 🔍 Notas Importantes

### Limitaciones visionOS
- **Sin SwiftData:** visionOS no usa base de datos local
- **Solo Cloud:** Toda la data viene del servidor
- **Requiere autenticación iOS/iPad:** Login desde otro dispositivo

### Consideraciones de UX
- UI espacial y grande (pantallas flotantes)
- Gestos naturales (tap, pinch, swipe)
- Eye tracking para selección
- Profundidad y sombras para jerarquía

### Testing
- Simulador visionOS en Xcode
- Dispositivo real Vision Pro si es posible
- Probar diferentes configuraciones de espacio

---

**Siguiente paso:** ¿Empezamos con el PASO 1 (Crear visionOS Target)?
