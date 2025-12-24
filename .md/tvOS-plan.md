# Plan de Acción: tvOS App

> **Objetivo:** Implementar una app para Apple TV que muestre la colección de mangas optimizada para pantalla grande y control remoto.

---

## 📋 Requisitos de la App tvOS

### Funcionalidades Mínimas
1. Ver colección de mangas en grid grande
2. Navegar con Siri Remote (focus engine)
3. Ver detalles de cada manga
4. Actualizar volumen de lectura
5. Interfaz optimizada para sala de estar (10ft UI)

### Características tvOS
- UI grande y clara (vista desde 3+ metros)
- Navegación con focus engine
- Siri Remote / gamepad support
- Parallax effects
- Sin SwiftData (solo red/UserDefaults)
- Top Shelf extension (opcional)

---

## 🏗️ Arquitectura del Proyecto

### Estructura de Carpetas
```
MisMangas/
├── MisMangas/              # App iOS (ya existe)
├── MisMangas tvOS/         # NUEVO - App tvOS
│   ├── MisMangasApp.swift
│   ├── ContentView.swift
│   ├── Views/
│   │   ├── TVRootView.swift
│   │   ├── TVCollectionView.swift
│   │   ├── TVMangaCard.swift
│   │   └── TVMangaDetailView.swift
│   └── Assets.xcassets
└── Shared/                 # Código compartido
    ├── Models/             # Ya existe - reutilizar
    ├── ViewModels/         # Ya existe - reutilizar
    └── Network/            # Ya existe - reutilizar
```

---

## 📝 Plan de Implementación Paso a Paso

### PASO 1: Crear tvOS Target

**Acciones:**
1. En Xcode: File → New → Target
2. Seleccionar: **tvOS** → **App**
3. Nombre: `MisMangas tvOS`
4. Language: Swift
5. Interface: SwiftUI
6. Click "Finish"

**Resultado esperado:**
- Nuevo folder `MisMangas tvOS` en el proyecto
- Nuevo scheme `MisMangas tvOS`

---

### PASO 2: Configurar App Groups

**¿Por qué?** Para compartir el token de autenticación entre plataformas.

**Acciones tvOS:**
1. Seleccionar target `MisMangas tvOS`
2. Signing & Capabilities → + Capability
3. Agregar **App Groups**
4. Seleccionar: `group.com.mismangas.shared` (ya existe)

---

### PASO 3: Compartir Código Existente

**Archivos a compartir con tvOS:**

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
3. Target Membership → Marcar `MisMangas tvOS`

---

### PASO 4: App Principal tvOS

**Archivo:** `MisMangas tvOS/MisMangasApp.swift`

```swift
import SwiftUI

@main
struct MisMangas_tvOS_App: App {
    @State private var authVM: AuthViewModel
    @State private var cloudVM: CloudCollectionViewModel

    init() {
        let auth = AuthViewModel()
        _authVM = State(initialValue: auth)
        _cloudVM = State(initialValue: CloudCollectionViewModel(authVM: auth))
    }

    var body: some Scene {
        WindowGroup {
            TVRootView()
                .environment(authVM)
                .environment(cloudVM)
        }
    }
}
```

---

### PASO 5: Vista Principal (Root)

**Archivo:** `MisMangas tvOS/Views/TVRootView.swift`

```swift
import SwiftUI

struct TVRootView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            // Tab 1: Colección
            NavigationStack {
                Group {
                    if !authVM.isAuthenticated {
                        TVLoginPromptView()
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
                        TVCollectionView()
                    }
                }
            }
            .tabItem {
                Label("Colección", systemImage: "books.vertical")
            }

            // Tab 2: Perfil
            NavigationStack {
                TVProfileView()
            }
            .tabItem {
                Label("Perfil", systemImage: "person.circle")
            }
        }
        .task {
            if authVM.isAuthenticated {
                await cloudVM.loadCollection()
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && authVM.isAuthenticated {
                Task {
                    await cloudVM.loadCollection()
                }
            }
        }
    }
}

struct TVLoginPromptView: View {
    var body: some View {
        VStack(spacing: 60) {
            Image(systemName: "appletvremote.gen1")
                .font(.system(size: 150))
                .foregroundStyle(.blue)

            VStack(spacing: 30) {
                Text("Bienvenido a MisMangas")
                    .font(.system(size: 72, weight: .bold))

                Text("Inicia sesión desde tu iPhone o iPad para acceder a tu colección")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 1200)
            }
        }
        .padding(120)
    }
}

struct TVProfileView: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        VStack(spacing: 40) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 200))
                .foregroundStyle(.blue)

            if authVM.isAuthenticated, let email = authVM.userEmail {
                Text(email)
                    .font(.system(size: 48, weight: .semibold))
            } else {
                Text("No autenticado")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
            }

            Text("Gestiona tu cuenta desde iPhone o iPad")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
        }
        .padding(120)
    }
}
```

---

### PASO 6: Vista de Colección (Grid TV)

**Archivo:** `MisMangas tvOS/Views/TVCollectionView.swift`

```swift
import SwiftUI

struct TVCollectionView: View {
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    // Grid 4x3 optimizado para TV (1920x1080)
    private let columns = [
        GridItem(.fixed(400), spacing: 60),
        GridItem(.fixed(400), spacing: 60),
        GridItem(.fixed(400), spacing: 60),
        GridItem(.fixed(400), spacing: 60)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 80) {
                ForEach(cloudVM.cloudCollection) { item in
                    NavigationLink(value: item.id) {
                        TVMangaCard(item: item)
                    }
                    .buttonStyle(.card)
                }
            }
            .padding(80)
        }
        .navigationTitle("Mi Colección")
        .navigationDestination(for: String.self) { itemId in
            if let item = cloudVM.cloudCollection.first(where: { $0.id == itemId }) {
                TVMangaDetailView(item: item)
            }
        }
    }
}
```

---

### PASO 7: Card de Manga (con Focus Effect)

**Archivo:** `MisMangas tvOS/Views/TVMangaCard.swift`

```swift
import SwiftUI

struct TVMangaCard: View {
    let item: UserMangaCollection

    @Environment(\.isFocused) private var isFocused

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Portada
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
                                .font(.system(size: 60))
                                .foregroundStyle(.gray)
                        }
                @unknown default:
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                }
            }
            .frame(width: 400, height: 600)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: isFocused ? 30 : 10)

            // Info
            VStack(alignment: .leading, spacing: 12) {
                Text(item.manga.title)
                    .font(.system(size: 32, weight: .bold))
                    .lineLimit(2)
                    .frame(height: 80, alignment: .top)

                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 24))
                    Text(String(format: "%.2f", item.manga.score))
                        .font(.system(size: 28, weight: .semibold))
                }

                // Progreso
                if let total = item.manga.volumes {
                    let reading = item.readingVolume ?? 1
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vol. \(reading)/\(total)")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)

                        ProgressView(value: Double(reading), total: Double(total))
                            .frame(width: 400)
                            .scaleEffect(y: 2.0) // Más grueso en TV
                    }
                }
            }
        }
        .frame(width: 400)
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isFocused)
    }
}
```

---

### PASO 8: Vista de Detalle

**Archivo:** `MisMangas tvOS/Views/TVMangaDetailView.swift`

```swift
import SwiftUI

struct TVMangaDetailView: View {
    let item: UserMangaCollection

    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.dismiss) private var dismiss

    @State private var currentVolume: Int
    @State private var isSaving = false
    @FocusState private var focusedButton: FocusButton?

    enum FocusButton {
        case decrease, increase, save
    }

    init(item: UserMangaCollection) {
        self.item = item
        _currentVolume = State(initialValue: item.readingVolume ?? 1)
    }

    var updatedItem: UserMangaCollection {
        cloudVM.cloudCollection.first(where: { $0.id == item.id }) ?? item
    }

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 100) {
                // Portada grande
                AsyncImage(url: URL(string: updatedItem.manga.mainPicture.replacingOccurrences(of: "\"", with: ""))) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 500, height: 750)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .shadow(radius: 40)

                // Información y controles
                VStack(alignment: .leading, spacing: 50) {
                    Text(updatedItem.manga.title)
                        .font(.system(size: 64, weight: .bold))
                        .lineLimit(3)

                    // Stats
                    HStack(spacing: 80) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Puntuación")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.system(size: 36))
                                Text(String(format: "%.2f", updatedItem.manga.score))
                                    .font(.system(size: 52, weight: .bold))
                            }
                        }

                        if let volumes = updatedItem.manga.volumes {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Volúmenes")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.secondary)
                                Text("\(volumes)")
                                    .font(.system(size: 52, weight: .bold))
                            }
                        }
                    }

                    Divider()

                    // Control de progreso
                    VStack(alignment: .leading, spacing: 30) {
                        Text("Tu Progreso")
                            .font(.system(size: 48, weight: .bold))

                        HStack(spacing: 40) {
                            Button {
                                if currentVolume > 1 {
                                    currentVolume -= 1
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 60))
                            }
                            .disabled(currentVolume <= 1)
                            .focused($focusedButton, equals: .decrease)

                            Text("Volumen \(currentVolume)")
                                .font(.system(size: 52, weight: .bold))
                                .frame(minWidth: 400)

                            Button {
                                if let max = updatedItem.manga.volumes, currentVolume < max {
                                    currentVolume += 1
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 60))
                            }
                            .disabled(currentVolume >= (updatedItem.manga.volumes ?? 999))
                            .focused($focusedButton, equals: .increase)
                        }

                        if let total = updatedItem.manga.volumes {
                            VStack(alignment: .leading, spacing: 16) {
                                ProgressView(value: Double(currentVolume), total: Double(total))
                                    .scaleEffect(y: 3.0)
                                    .frame(maxWidth: 800)

                                Text("\(Int((Double(currentVolume) / Double(total)) * 100))% completado")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Divider()

                    // Botón guardar
                    Button {
                        Task {
                            await saveProgress()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Label("Guardar Progreso", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 36, weight: .semibold))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isSaving || currentVolume == updatedItem.readingVolume)
                    .focused($focusedButton, equals: .save)
                }
                .frame(maxWidth: 900)
            }
            .padding(120)
        }
        .navigationTitle(updatedItem.manga.title)
        .onAppear {
            focusedButton = .increase
        }
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

## ✅ Checklist de Implementación

### Setup Inicial
- [ ] Crear tvOS target en Xcode
- [ ] Configurar App Groups (tvOS)
- [ ] Compartir archivos de Models con tvOS
- [ ] Compartir Network layer con tvOS
- [ ] Compartir KeychainHelper con tvOS
- [ ] Compartir ViewModels con tvOS

### Vistas tvOS
- [ ] Crear MisMangasApp.swift
- [ ] Crear TVRootView.swift
- [ ] Crear TVLoginPromptView
- [ ] Crear TVProfileView
- [ ] Crear TVCollectionView.swift
- [ ] Crear TVMangaCard.swift
- [ ] Crear TVMangaDetailView.swift

### Funcionalidades
- [ ] Cargar colección desde cloud
- [ ] Mostrar grid optimizado para TV
- [ ] Navegar con Siri Remote (focus engine)
- [ ] Actualizar volumen de lectura
- [ ] Sincronizar con servidor
- [ ] Focus effects y animaciones

### Testing
- [ ] Probar en simulador tvOS
- [ ] Verificar compartición de token
- [ ] Probar navegación con Siri Remote
- [ ] Verificar sincronización
- [ ] Probar desde 3+ metros (10ft UI test)

---

## 🎯 Resultado Final

Al completar este plan tendrás:

✅ App tvOS funcional
✅ UI optimizada para sala de estar
✅ Navegación con Siri Remote
✅ Ver y actualizar colección en TV
✅ Compartir autenticación entre plataformas
✅ Focus effects y animaciones

---

## 🔍 Notas Importantes

### Limitaciones tvOS
- **Sin SwiftData:** tvOS no usa base de datos local
- **Solo Cloud:** Toda la data viene del servidor
- **Requiere autenticación iOS/iPad:** Login desde otro dispositivo
- **Sin teclado nativo:** Entrada de texto complicada

### Consideraciones de UX (10ft UI)
- **Textos grandes:** Mínimo 28pt para leer desde lejos
- **Elementos grandes:** Botones y cards amplios
- **Alto contraste:** Visible en diferentes condiciones de luz
- **Focus engine:** Navegación clara con Siri Remote
- **Animaciones suaves:** Feedback visual de selección

### Tamaños recomendados
- Títulos: 48-72pt
- Subtítulos: 32-40pt
- Cuerpo: 28-32pt
- Cards: 400x600px mínimo
- Spacing: 60-80px entre elementos

### Testing
- Simulador tvOS en Xcode
- Apple TV real si es posible
- Probar desde 3+ metros de distancia
- Verificar legibilidad en diferentes TVs

---

## 🎮 Atajos de Siri Remote

| Acción | Gesto |
|--------|-------|
| Seleccionar | Click en trackpad |
| Volver | Botón Menu |
| Scroll | Swipe en trackpad |
| Activar Siri | Mantener botón Siri |
| Play/Pause | Click en botón Play/Pause |

---

**Siguiente paso:** ¿Empezamos con el PASO 1 (Crear tvOS Target)?
