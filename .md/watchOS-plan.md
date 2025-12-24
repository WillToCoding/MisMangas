# Plan de Acción: watchOS App

> **Objetivo:** Implementar una app para Apple Watch que muestre la colección de mangas y permita actualizar el progreso de lectura.

---

## 📋 Requisitos de la App watchOS

### Funcionalidades Mínimas
1. Ver colección de mangas desde la nube
2. Ver detalles básicos de cada manga
3. Actualizar volumen de lectura actual
4. Sincronizar con el servidor

### Restricciones watchOS
- UI simplificada (pantalla pequeña)
- Sin SwiftData (usar solo red/UserDefaults)
- Navegación con Digital Crown
- Sin imágenes grandes (optimize bandwidth)

---

## 🏗️ Arquitectura del Proyecto

### Estructura de Carpetas
```
MisMangas/
├── MisMangas/              # App iOS (ya existe)
├── MisMangas Watch App/    # NUEVO - App watchOS
│   ├── MisMangasApp.swift
│   ├── ContentView.swift
│   ├── Views/
│   │   ├── WatchMangaRow.swift
│   │   ├── WatchMangaDetailView.swift
│   │   └── WatchUpdateProgressView.swift
│   └── Assets.xcassets
└── Shared/                 # Código compartido
    ├── Models/             # Ya existe - reutilizar
    ├── ViewModels/         # Ya existe - reutilizar
    └── Network/            # Ya existe - reutilizar
```

---

## 📝 Plan de Implementación Paso a Paso

### PASO 1: Crear watchOS Target

**Acciones:**
1. En Xcode: File → New → Target
2. Seleccionar: **watchOS** → **Watch App**
3. Nombre: `MisMangas Watch App`
4. Language: Swift
5. Interface: SwiftUI
6. Desmarcar: "Include Notification Scene"
7. Click "Finish"

**Resultado esperado:**
- Nuevo folder `MisMangas Watch App` en el proyecto
- Nuevo scheme `MisMangas Watch App`

---

### PASO 2: Configurar App Groups (Compartir datos)

**¿Por qué?** Para que iOS y watchOS compartan el token de autenticación.

**Acciones iOS:**
1. Seleccionar target `MisMangas` (iOS)
2. Signing & Capabilities → + Capability
3. Agregar **App Groups**
4. Click "+" y crear: `group.com.mismangas.shared`

**Acciones watchOS:**
1. Seleccionar target `MisMangas Watch App`
2. Signing & Capabilities → + Capability
3. Agregar **App Groups**
4. Seleccionar: `group.com.mismangas.shared`

---

### PASO 3: Compartir Código Existente

**Archivos a compartir con watchOS:**

1. **Models** (todos):
   - `ModelDTO.swift`
   - `AuthError.swift`
   - NO incluir `Model.swift` (es SwiftData, watchOS no lo necesita)

2. **Network**:
   - `NetworkRepository.swift`
   - `URL.swift`

3. **Storage**:
   - `KeychainHelper.swift`

**Cómo compartir:**
1. Seleccionar archivo en navegador
2. Inspector de archivos (⌥⌘1)
3. Target Membership → Marcar `MisMangas Watch App`

---

### PASO 4: Crear ViewModels compartidos

**Opción A: Compartir ViewModels existentes** (Recomendado)
- Marcar `AuthViewModel.swift` con target watchOS
- Marcar `CloudCollectionViewModel.swift` con target watchOS

**Opción B: Crear ViewModels específicos watchOS**
- Si los existentes tienen dependencias de SwiftUI iOS

---

### PASO 5: App Principal watchOS

**Archivo:** `MisMangas Watch App/MisMangasApp.swift`

```swift
import SwiftUI

@main
struct MisMangas_Watch_App: App {
    @State private var authVM = AuthViewModel()
    @State private var cloudVM: CloudCollectionViewModel?

    init() {
        let auth = AuthViewModel()
        _authVM = State(initialValue: auth)
        _cloudVM = State(initialValue: CloudCollectionViewModel(authVM: auth))
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(authVM)
                .environment(cloudVM!)
        }
    }
}
```

---

### PASO 6: Vista Principal (Root)

**Archivo:** `MisMangas Watch App/Views/WatchRootView.swift`

```swift
import SwiftUI

struct WatchRootView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    var body: some View {
        NavigationStack {
            if !authVM.isAuthenticated {
                WatchLoginPromptView()
            } else if cloudVM.isLoading {
                ProgressView("Cargando...")
            } else if cloudVM.cloudCollection.isEmpty {
                ContentUnavailableView(
                    "Sin Mangas",
                    systemImage: "book",
                    description: Text("Añade mangas desde tu iPhone")
                )
            } else {
                WatchCollectionView()
            }
        }
        .task {
            if authVM.isAuthenticated {
                await cloudVM.loadCollection()
            }
        }
    }
}

struct WatchLoginPromptView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "applewatch.and.iphone")
                .font(.largeTitle)
                .foregroundStyle(.blue)

            Text("Inicia Sesión")
                .font(.headline)

            Text("Usa la app de iPhone para iniciar sesión")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
```

---

### PASO 7: Lista de Colección

**Archivo:** `MisMangas Watch App/Views/WatchCollectionView.swift`

```swift
import SwiftUI

struct WatchCollectionView: View {
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    var body: some View {
        List {
            ForEach(cloudVM.cloudCollection) { item in
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
}
```

---

### PASO 8: Fila de Manga (Row)

**Archivo:** `MisMangas Watch App/Views/WatchMangaRow.swift`

```swift
import SwiftUI

struct WatchMangaRow: View {
    let item: UserMangaCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.manga.title)
                .font(.headline)
                .lineLimit(2)

            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption2)

                Text(String(format: "%.1f", item.manga.score))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Progress
            if let reading = item.readingVolume, let total = item.manga.volumes {
                HStack(spacing: 4) {
                    Text("Vol. \(reading)/\(total)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    ProgressView(value: Double(reading), total: Double(total))
                        .frame(width: 50)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
```

---

### PASO 9: Vista de Detalle

**Archivo:** `MisMangas Watch App/Views/WatchMangaDetailView.swift`

```swift
import SwiftUI

struct WatchMangaDetailView: View {
    let item: UserMangaCollection

    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.dismiss) private var dismiss

    @State private var currentVolume: Int
    @State private var isSaving = false

    init(item: UserMangaCollection) {
        self.item = item
        _currentVolume = State(initialValue: item.readingVolume ?? 0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Título
                Text(item.manga.title)
                    .font(.headline)

                // Puntuación
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.2f", item.manga.score))
                }
                .font(.caption)

                Divider()

                // Volumen actual
                VStack(alignment: .leading, spacing: 8) {
                    Text("Volumen Actual")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Stepper(
                        value: $currentVolume,
                        in: 0...(item.manga.volumes ?? 999)
                    ) {
                        Text("Vol. \(currentVolume)")
                            .font(.title3.bold())
                    }
                }

                // Progress
                if let total = item.manga.volumes, total > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Progreso")
                                .font(.caption)
                            Spacer()
                            Text("\(Int((Double(currentVolume) / Double(total)) * 100))%")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)

                        ProgressView(value: Double(currentVolume), total: Double(total))
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
                        Label("Guardar", systemImage: "checkmark.circle.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving || currentVolume == item.readingVolume)
            }
            .padding()
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveProgress() async {
        isSaving = true

        do {
            try await cloudVM.addToCollection(
                manga: item.manga,
                volumesOwned: item.volumesOwned,
                readingVolume: currentVolume,
                completeCollection: item.completeCollection
            )

            // Pequeña vibración de éxito
            WKInterfaceDevice.current().play(.success)

            // Cerrar vista después de guardar
            try? await Task.sleep(for: .seconds(0.5))
            dismiss()
        } catch {
            print("Error guardando progreso: \(error)")
            WKInterfaceDevice.current().play(.failure)
        }

        isSaving = false
    }
}
```

---

### PASO 10: Actualizar KeychainHelper para App Groups

**Modificar:** `MisMangas/Storage/KeychainHelper.swift`

```swift
final class KeychainHelper {
    // Añadir access group para compartir entre iOS y watchOS
    private let accessGroup = "group.com.mismangas.shared"

    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrAccessGroup as String: accessGroup  // NUEVO
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessGroup as String: accessGroup  // NUEVO
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: accessGroup  // NUEVO
        ]

        SecItemDelete(query as CFDictionary)
    }
}
```

---

## ✅ Checklist de Implementación

### Setup Inicial
- [ ] Crear watchOS target en Xcode
- [ ] Configurar App Groups (iOS + watchOS)
- [ ] Compartir archivos de Models con watchOS
- [ ] Compartir Network layer con watchOS
- [ ] Compartir KeychainHelper con watchOS
- [ ] Actualizar KeychainHelper con accessGroup

### ViewModels
- [ ] Compartir o crear AuthViewModel para watchOS
- [ ] Compartir o crear CloudCollectionViewModel para watchOS

### Vistas watchOS
- [ ] Crear MisMangasApp.swift
- [ ] Crear WatchRootView.swift
- [ ] Crear WatchLoginPromptView (mensaje para iniciar sesión en iPhone)
- [ ] Crear WatchCollectionView.swift
- [ ] Crear WatchMangaRow.swift
- [ ] Crear WatchMangaDetailView.swift

### Funcionalidades
- [ ] Cargar colección desde cloud
- [ ] Mostrar lista de mangas
- [ ] Navegar a detalle
- [ ] Actualizar volumen de lectura
- [ ] Sincronizar con servidor
- [ ] Feedback háptico (success/failure)

### Testing
- [ ] Probar en simulador watchOS
- [ ] Verificar que comparte token entre iOS y watchOS
- [ ] Probar actualización de progreso
- [ ] Verificar sincronización

---

## 🎯 Resultado Final

Al completar este plan tendrás:

✅ App watchOS funcional
✅ Ver colección en Apple Watch
✅ Actualizar progreso de lectura
✅ Sincronización con cloud
✅ Compartir autenticación entre iOS y watchOS
✅ Feedback háptico

---

## 🔍 Notas Importantes

### Limitaciones watchOS
- **Sin SwiftData:** watchOS no puede usar la base de datos local
- **Solo Cloud:** Toda la data viene del servidor
- **Debe estar autenticado en iOS:** El login se hace desde iPhone

### Consideraciones de UX
- UI minimalista (pantalla pequeña)
- Solo mostrar info esencial
- Digital Crown para navegación
- Feedback háptico para confirmar acciones

### Testing
- Usar simulador watchOS en Xcode
- Probar con diferentes tamaños de Apple Watch
- Verificar en dispositivo real si es posible

---

**Siguiente paso:** ¿Empezamos con el PASO 1 (Crear watchOS Target)?
