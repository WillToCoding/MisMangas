# Plan de Acción: macOS App (SwiftUI Nativo)

> **Objetivo:** Implementar una app nativa para macOS que aproveche NavigationSplitView, menús nativos y el poder de una pantalla grande.

---

## 📋 Requisitos de la App macOS

### Funcionalidades Mínimas
1. Ver catálogo completo de mangas
2. Búsqueda y filtros avanzados
3. Vista detalle en panel separado
4. Gestión de colección (local y cloud)
5. Autenticación de usuarios

### Características macOS
- NavigationSplitView (3 columnas: Sidebar, Lista, Detalle)
- Menú bar nativo
- Toolbar con acciones
- Keyboard shortcuts
- Múltiples ventanas
- Drag & drop (opcional)

---

## 🏗️ Arquitectura del Proyecto

### Estructura de Carpetas
```
MisMangas/
├── MisMangas/              # App iOS (ya existe)
├── MisMangas macOS/        # NUEVO - App macOS
│   ├── MisMangasApp.swift
│   ├── MacMainView.swift
│   ├── Views/
│   │   ├── Sidebar/
│   │   │   └── MacSidebarView.swift
│   │   ├── List/
│   │   │   ├── MacMangaListView.swift
│   │   │   └── MacMangaRow.swift
│   │   ├── Detail/
│   │   │   └── MacMangaDetailView.swift
│   │   ├── Collection/
│   │   │   └── MacCollectionView.swift
│   │   └── Auth/
│   │       ├── MacLoginView.swift
│   │       └── MacRegisterView.swift
│   └── Assets.xcassets
└── Shared/                 # Código compartido
    ├── Models/             # Ya existe - reutilizar
    ├── ViewModels/         # Ya existe - reutilizar
    └── Network/            # Ya existe - reutilizar
```

---

## 📝 Plan de Implementación Paso a Paso

### PASO 1: Crear macOS Target

**Acciones:**
1. En Xcode: File → New → Target
2. Seleccionar: **macOS** → **App**
3. Nombre: `MisMangas macOS`
4. Interface: SwiftUI
5. Language: Swift
6. Click "Finish"

**Configuración adicional:**
1. Seleccionar target `MisMangas macOS`
2. General → Deployment Info:
   - macOS 14.0 o superior
3. Signing & Capabilities:
   - Signing automático
   - Bundle Identifier: `com.mismangas.macos`

**Resultado esperado:**
- Nuevo folder `MisMangas macOS` en el proyecto
- Nuevo scheme `MisMangas macOS`

---

### PASO 2: Compartir Código Existente

**Archivos a compartir con macOS:**

**Models (todos):**
- `ModelDTO.swift` ✓
- `AuthError.swift` ✓
- `FilterModel.swift` ✓
- **NO** `Model.swift` (si solo quieres cloud, o SÍ si quieres SwiftData en Mac)

**Network:**
- `NetworkRepository.swift` ✓
- `URL.swift` ✓

**Storage:**
- `KeychainHelper.swift` ✓

**ViewModels:**
- `AuthViewModel.swift` ✓
- `CloudCollectionViewModel.swift` ✓
- `MangaViewModel.swift` ✓
- `FilterViewModel.swift` ✓

**Cómo compartir:**
1. Seleccionar archivo
2. Inspector (⌥⌘1)
3. Target Membership → Marcar `MisMangas macOS`

---

### PASO 3: App Principal macOS

**Archivo:** `MisMangas macOS/MisMangasApp.swift`

```swift
import SwiftUI
import SwiftData

@main
struct MisMangas_macOS_App: App {
    @State private var authVM = AuthViewModel()
    @State private var mangaVM = MangaViewModel()
    @State private var filterVM = FilterViewModel()
    @State private var cloudVM: CloudCollectionViewModel?

    init() {
        let auth = AuthViewModel()
        _authVM = State(initialValue: auth)
        _cloudVM = State(initialValue: CloudCollectionViewModel(authVM: auth))
    }

    var body: some Scene {
        WindowGroup {
            MacMainView()
                .environment(authVM)
                .environment(mangaVM)
                .environment(filterVM)
                .environment(cloudVM!)
                .frame(minWidth: 900, minHeight: 600)
        }
        .commands {
            MacCommands()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)

        // Ventana de preferencias (opcional)
        Settings {
            MacPreferencesView()
                .environment(authVM)
        }
    }
}

// Comandos del menú
struct MacCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Buscar Manga...") {
                // Acción búsqueda
            }
            .keyboardShortcut("f", modifiers: .command)

            Divider()

            Button("Actualizar") {
                // Refrescar
            }
            .keyboardShortcut("r", modifiers: .command)
        }
    }
}
```

---

### PASO 4: Vista Principal (NavigationSplitView)

**Archivo:** `MisMangas macOS/MacMainView.swift`

```swift
import SwiftUI

enum NavigationItem: Hashable {
    case explore
    case collection
    case bestMangas
}

struct MacMainView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(MangaViewModel.self) private var mangaVM

    @State private var selectedSection: NavigationItem? = .explore
    @State private var selectedManga: Manga?
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // SIDEBAR (Columna 1)
            MacSidebarView(selection: $selectedSection)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)

        } content: {
            // LISTA (Columna 2)
            Group {
                switch selectedSection {
                case .explore:
                    MacMangaListView(selection: $selectedManga)
                case .collection:
                    MacCollectionView(selection: $selectedManga)
                case .bestMangas:
                    MacBestMangasView(selection: $selectedManga)
                case .none:
                    ContentUnavailableView(
                        "Selecciona una sección",
                        systemImage: "sidebar.left"
                    )
                }
            }
            .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 500)

        } detail: {
            // DETALLE (Columna 3)
            if let manga = selectedManga {
                MacMangaDetailView(manga: manga)
            } else {
                ContentUnavailableView(
                    "Selecciona un manga",
                    systemImage: "book.closed",
                    description: Text("Elige un manga de la lista para ver sus detalles")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    withAnimation {
                        columnVisibility = columnVisibility == .all ? .detailOnly : .all
                    }
                } label: {
                    Label("Toggle Sidebar", systemImage: "sidebar.left")
                }
            }

            ToolbarItem {
                if authVM.isAuthenticated {
                    Text("👤 \(authVM.userEmail ?? "")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Button("Iniciar Sesión") {
                        // Mostrar login
                    }
                }
            }
        }
    }
}
```

---

### PASO 5: Sidebar (Navegación)

**Archivo:** `MisMangas macOS/Views/Sidebar/MacSidebarView.swift`

```swift
import SwiftUI

struct MacSidebarView: View {
    @Binding var selection: NavigationItem?
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        List(selection: $selection) {
            Section("Explorar") {
                Label("Todos los Mangas", systemImage: "books.vertical")
                    .tag(NavigationItem.explore)

                Label("Mejor Valorados", systemImage: "star.fill")
                    .tag(NavigationItem.bestMangas)
            }

            Section("Biblioteca") {
                Label("Mi Colección", systemImage: "folder.fill")
                    .tag(NavigationItem.collection)
                    .badge(authVM.isAuthenticated ? "Cloud" : "Local")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("MisMangas")
    }
}
```

---

### PASO 6: Lista de Mangas

**Archivo:** `MisMangas macOS/Views/List/MacMangaListView.swift`

```swift
import SwiftUI

struct MacMangaListView: View {
    @Binding var selection: Manga?
    @Environment(MangaViewModel.self) private var mangaVM
    @Environment(FilterViewModel.self) private var filterVM

    @State private var searchText = ""
    @State private var showFilters = false

    var body: some View {
        VStack(spacing: 0) {
            // Barra de búsqueda y filtros
            HStack {
                TextField("Buscar mangas...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task {
                            await performSearch()
                        }
                    }

                Button {
                    showFilters.toggle()
                } label: {
                    Label("Filtros", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
            .padding()

            Divider()

            // Lista
            if mangaVM.isLoading {
                ProgressView("Cargando mangas...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = mangaVM.errorMessage {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                List(mangaVM.mangas, selection: $selection) { manga in
                    MacMangaRow(manga: manga)
                        .tag(manga)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Explorar")
        .sheet(isPresented: $showFilters) {
            MacFiltersSheet()
                .environment(filterVM)
        }
        .task {
            if mangaVM.mangas.isEmpty {
                await mangaVM.fetchMangas()
            }
            await filterVM.loadFilterOptions()
        }
    }

    private func performSearch() async {
        if searchText.isEmpty {
            await mangaVM.fetchMangas()
        } else {
            await mangaVM.searchMangas(text: searchText, contains: true)
        }
    }
}
```

---

### PASO 7: Fila de Manga

**Archivo:** `MisMangas macOS/Views/List/MacMangaRow.swift`

```swift
import SwiftUI

struct MacMangaRow: View {
    let manga: Manga

    var body: some View {
        HStack(spacing: 12) {
            // Miniatura
            AsyncImage(url: URL(string: manga.mainPicture.replacingOccurrences(of: "\"", with: ""))) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 40, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(manga.title)
                    .font(.headline)
                    .lineLimit(1)

                if let english = manga.titleEnglish {
                    Text(english)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption2)

                    Text(String(format: "%.2f", manga.score))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let volumes = manga.volumes {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text("\(volumes) vols")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
```

---

### PASO 8: Vista de Detalle

**Archivo:** `MisMangas macOS/Views/Detail/MacMangaDetailView.swift`

```swift
import SwiftUI

struct MacMangaDetailView: View {
    let manga: Manga

    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(AuthViewModel.self) private var authVM

    @State private var showAddToCollection = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header con imagen y datos principales
                HStack(alignment: .top, spacing: 24) {
                    // Portada
                    AsyncImage(url: URL(string: manga.mainPicture.replacingOccurrences(of: "\"", with: ""))) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 250, height: 375)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 8)

                    // Información principal
                    VStack(alignment: .leading, spacing: 16) {
                        Text(manga.title)
                            .font(.largeTitle.bold())

                        if let english = manga.titleEnglish {
                            Text(english)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }

                        if let japanese = manga.titleJapanese {
                            Text(japanese)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        // Stats
                        HStack(spacing: 24) {
                            VStack(alignment: .leading) {
                                Text("Puntuación")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                    Text(String(format: "%.2f", manga.score))
                                        .font(.title2.bold())
                                }
                            }

                            if let volumes = manga.volumes {
                                VStack(alignment: .leading) {
                                    Text("Volúmenes")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(volumes)")
                                        .font(.title2.bold())
                                }
                            }

                            if let chapters = manga.chapters {
                                VStack(alignment: .leading) {
                                    Text("Capítulos")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(chapters)")
                                        .font(.title2.bold())
                                }
                            }

                            VStack(alignment: .leading) {
                                Text("Estado")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(manga.status.capitalized)
                                    .font(.headline)
                                    .foregroundStyle(manga.status == "finished" ? .green : .blue)
                            }
                        }

                        Divider()

                        // Botón de acción
                        Button {
                            showAddToCollection = true
                        } label: {
                            Label(
                                authVM.isAuthenticated && cloudVM.isInCollection(manga.id) ? "En Colección" : "Añadir a Colección",
                                systemImage: "plus.circle.fill"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }

                Divider()

                // Autores
                if !manga.authors.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Autores")
                            .font(.title2.bold())

                        ForEach(manga.authors) { author in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(.blue)
                                    .font(.title3)

                                VStack(alignment: .leading) {
                                    Text("\(author.firstName) \(author.lastName)")
                                        .font(.headline)
                                    Text(author.role)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                // Géneros, temas, demografía
                if !manga.genres.isEmpty || !manga.themes.isEmpty || !manga.demographics.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Categorías")
                            .font(.title2.bold())

                        if !manga.genres.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Géneros")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                FlowLayout(spacing: 8) {
                                    ForEach(manga.genres) { genre in
                                        Text(genre.genre)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(.blue.opacity(0.2))
                                            .foregroundStyle(.blue)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        if !manga.themes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Temas")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                FlowLayout(spacing: 8) {
                                    ForEach(manga.themes) { theme in
                                        Text(theme.theme)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(.purple.opacity(0.2))
                                            .foregroundStyle(.purple)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        if !manga.demographics.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Demografía")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                FlowLayout(spacing: 8) {
                                    ForEach(manga.demographics) { demo in
                                        Text(demo.demographic)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(.green.opacity(0.2))
                                            .foregroundStyle(.green)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                }

                // Sinopsis
                if let synopsis = manga.sypnosis {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sinopsis")
                            .font(.title2.bold())

                        Text(synopsis)
                            .lineSpacing(6)
                    }
                }

                // Background
                if let background = manga.background {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Información Adicional")
                            .font(.title2.bold())

                        Text(background)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineSpacing(6)
                    }
                }
            }
            .padding(32)
        }
        .navigationTitle(manga.title)
        .sheet(isPresented: $showAddToCollection) {
            AddToCollectionView(manga: manga)
                .frame(width: 500, height: 600)
        }
    }
}
```

---

### PASO 9: Vista de Colección

**Archivo:** `MisMangas macOS/Views/Collection/MacCollectionView.swift`

```swift
import SwiftUI

struct MacCollectionView: View {
    @Binding var selection: Manga?

    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(authVM.isAuthenticated ? "Colección Cloud" : "Colección Local")
                    .font(.headline)

                Spacer()

                if authVM.isAuthenticated {
                    Image(systemName: "cloud.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding()

            Divider()

            // Lista
            if authVM.isAuthenticated {
                if cloudVM.isLoading {
                    ProgressView("Cargando colección...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if cloudVM.cloudCollection.isEmpty {
                    ContentUnavailableView(
                        "Sin Mangas",
                        systemImage: "books.vertical",
                        description: Text("Añade mangas a tu colección")
                    )
                } else {
                    List(cloudVM.cloudCollection, selection: Binding(
                        get: { selection },
                        set: { newValue in
                            selection = cloudVM.cloudCollection.first { $0.id == newValue?.id.description }?.manga
                        }
                    )) { item in
                        MacMangaRow(manga: item.manga)
                            .tag(item.manga)
                            .contextMenu {
                                Button("Eliminar de Colección", role: .destructive) {
                                    Task {
                                        try? await cloudVM.removeFromCollection(mangaId: item.manga.id)
                                    }
                                }
                            }
                    }
                }
            } else {
                ContentUnavailableView(
                    "Inicia Sesión",
                    systemImage: "person.circle",
                    description: Text("Inicia sesión para ver tu colección")
                )
            }
        }
        .navigationTitle("Mi Colección")
        .task {
            if authVM.isAuthenticated {
                await cloudVM.loadCollection()
            }
        }
    }
}
```

---

### PASO 10: Preferencias (Opcional)

**Archivo:** `MisMangas macOS/Views/MacPreferencesView.swift`

```swift
import SwiftUI

struct MacPreferencesView: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        TabView {
            // General
            Form {
                Section("Cuenta") {
                    if authVM.isAuthenticated {
                        LabeledContent("Email", value: authVM.userEmail ?? "")
                        Button("Cerrar Sesión", role: .destructive) {
                            authVM.logout()
                        }
                    } else {
                        Text("No has iniciado sesión")
                        Button("Iniciar Sesión") {
                            // Mostrar login
                        }
                    }
                }
            }
            .padding()
            .frame(width: 450, height: 300)
            .tabItem {
                Label("General", systemImage: "gearshape")
            }

            // Apariencia
            Form {
                Section("Apariencia") {
                    Picker("Tema", selection: .constant("auto")) {
                        Text("Automático").tag("auto")
                        Text("Claro").tag("light")
                        Text("Oscuro").tag("dark")
                    }
                }
            }
            .padding()
            .frame(width: 450, height: 300)
            .tabItem {
                Label("Apariencia", systemImage: "paintbrush")
            }
        }
    }
}
```

---

## ✅ Checklist de Implementación

### Setup Inicial
- [ ] Crear macOS target en Xcode
- [ ] Configurar deployment target (macOS 14.0+)
- [ ] Compartir archivos de Models
- [ ] Compartir Network layer
- [ ] Compartir ViewModels
- [ ] Compartir KeychainHelper

### Estructura Principal
- [ ] Crear MisMangasApp.swift con WindowGroup
- [ ] Implementar MacCommands (menú)
- [ ] Crear MacMainView con NavigationSplitView

### Vistas
- [ ] Crear MacSidebarView (navegación)
- [ ] Crear MacMangaListView (lista principal)
- [ ] Crear MacMangaRow (fila)
- [ ] Crear MacMangaDetailView (detalle)
- [ ] Crear MacCollectionView (colección)
- [ ] Crear MacPreferencesView (preferencias)
- [ ] Crear MacFiltersSheet (filtros)

### Funcionalidades
- [ ] Navegación entre secciones
- [ ] Búsqueda de mangas
- [ ] Filtros avanzados
- [ ] Ver detalle en panel separado
- [ ] Añadir a colección
- [ ] Login/logout
- [ ] Keyboard shortcuts

### Testing
- [ ] Probar en macOS (simulador o real)
- [ ] Verificar NavigationSplitView en diferentes tamaños
- [ ] Probar keyboard shortcuts
- [ ] Verificar menú bar

---

## 🎯 Resultado Final

Al completar este plan tendrás:

✅ App macOS nativa funcional
✅ NavigationSplitView con 3 columnas
✅ Búsqueda y filtros completos
✅ Gestión de colección cloud
✅ Menú bar y toolbar nativos
✅ Keyboard shortcuts
✅ Ventana de preferencias

---

## 🔍 Notas Importantes

### Ventajas de macOS
- Pantalla grande → más información visible
- NavigationSplitView → navegación eficiente
- Keyboard shortcuts → productividad
- Múltiples ventanas → mejor multitarea

### Consideraciones de UX
- Aprovechar espacio en pantalla
- Menús contextuales (click derecho)
- Toolbar con acciones frecuentes
- Atajos de teclado intuitivos

### Testing
- Probar en diferentes tamaños de ventana
- Verificar modo claro/oscuro
- Probar con Magic Keyboard y trackpad
- Verificar en macOS real si es posible

---

**Siguiente paso:** ¿Empezamos con el PASO 1 (Crear macOS Target)?
