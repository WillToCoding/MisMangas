# Versión Media - Experiencia Completa con Filtros

> **Objetivo:** Construir sobre la versión básica añadiendo sistema completo de filtros, múltiples tipos de vistas y búsqueda avanzada.

---

## 📋 Requisitos según PDF

La versión media debe incluir:

1. ✅ **Todo lo de la versión básica**
   - Ver [versionBasica.md](versionBasica.md)

2. ⏳ **Conjunto completo de filtros**
   - Géneros (todos los disponibles)
   - Demografías (Shounen, Shoujo, Seinen, Josei, Kids)
   - Temáticas (todos los temas)
   - Combinación de filtros

3. ⏳ **Múltiples tipos de vista**
   - Listado (List) ✅ Ya lo tenemos
   - Grid (LazyVGrid)
   - Detalle (DetailView) - de versión básica

---

## ✅ Estado Actual (Ventaja desde Versión Básica)

### Ya Tenemos ✅
- [x] NetworkRepository con endpoints de filtrado
  - `getMangasByGenre()`
  - `getMangasByDemographic()`
  - `getMangasByTheme()`
- [x] ViewModel con funciones de filtrado
- [x] Modelos completos

### Lo que nos falta es UI y lógica de combinación de filtros

---

## 🎯 Nuevas Funcionalidades Requeridas

### 1. Sistema Completo de Filtros ⚠️ ALTA PRIORIDAD

#### Arquitectura de Filtros

**Modelo de Filtro:**
```swift
// En Models/FilterModel.swift
struct MangaFilters: Equatable {
    var genres: Set<String> = []
    var demographics: Set<String> = []
    var themes: Set<String> = []
    var searchText: String = ""
    var sortBy: SortOption = .score

    enum SortOption: String, CaseIterable {
        case score = "Puntuación"
        case title = "Título"
        case recent = "Más Recientes"
    }

    var isActive: Bool {
        !genres.isEmpty || !demographics.isEmpty || !themes.isEmpty || !searchText.isEmpty
    }

    func clear() -> MangaFilters {
        MangaFilters()
    }
}
```

**FilterViewModel:**
```swift
@Observable
final class FilterViewModel {
    var availableGenres: [String] = []
    var availableDemographics: [String] = []
    var availableThemes: [String] = []

    var isLoading = false
    private let repository = NetworkRepository()

    func loadFilterOptions() async {
        isLoading = true

        async let genres = repository.getGenres()
        async let demographics = repository.getDemographics()
        async let themes = repository.getThemes()

        do {
            availableGenres = try await genres
            availableDemographics = try await demographics
            availableThemes = try await themes
        } catch {
            // Handle error
        }

        isLoading = false
    }
}
```

**FilterView:**
```swift
struct FilterView: View {
    @Binding var filters: MangaFilters
    @State private var filterVM = FilterViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Sección de Géneros
                Section("Géneros") {
                    ForEach(filterVM.availableGenres, id: \.self) { genre in
                        Toggle(genre, isOn: Binding(
                            get: { filters.genres.contains(genre) },
                            set: { isOn in
                                if isOn {
                                    filters.genres.insert(genre)
                                } else {
                                    filters.genres.remove(genre)
                                }
                            }
                        ))
                    }
                }

                // Sección de Demografías
                Section("Demografías") {
                    ForEach(filterVM.availableDemographics, id: \.self) { demo in
                        Toggle(demo, isOn: Binding(
                            get: { filters.demographics.contains(demo) },
                            set: { isOn in
                                if isOn {
                                    filters.demographics.insert(demo)
                                } else {
                                    filters.demographics.remove(demo)
                                }
                            }
                        ))
                    }
                }

                // Sección de Temáticas
                Section("Temáticas") {
                    ForEach(filterVM.availableThemes, id: \.self) { theme in
                        Toggle(theme, isOn: Binding(
                            get: { filters.themes.contains(theme) },
                            set: { isOn in
                                if isOn {
                                    filters.themes.insert(theme)
                                } else {
                                    filters.themes.remove(theme)
                                }
                            }
                        ))
                    }
                }

                // Ordenamiento
                Section("Ordenar por") {
                    Picker("Orden", selection: $filters.sortBy) {
                        ForEach(MangaFilters.SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Aplicar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    Button("Limpiar Filtros") {
                        filters = filters.clear()
                    }
                    .disabled(!filters.isActive)
                }
            }
            .task {
                await filterVM.loadFilterOptions()
            }
        }
    }
}
```

**Tareas:**
- [ ] Crear `FilterModel.swift` con MangaFilters
- [ ] Crear `FilterViewModel.swift`
- [ ] Crear `FilterView.swift` con UI completa
- [ ] Integrar filtros en MangaViewModel
- [ ] Añadir botón de filtros en ContentView toolbar
- [ ] Implementar lógica de búsqueda con POST `/search/manga`

---

### 2. Vista Grid ⚠️ ALTA PRIORIDAD

**MangaGridView:**
```swift
struct MangaGridView: View {
    let mangas: [Manga]

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(mangas) { manga in
                    NavigationLink(value: manga) {
                        MangaGridCell(manga: manga)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

struct MangaGridCell: View {
    let manga: Manga

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Portada
            AsyncImage(url: URL(string: manga.mainPicture.replacingOccurrences(of: "\"", with: ""))) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 4)

            // Título
            Text(manga.title)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Score
            Label("\(manga.score, specifier: "%.1f")", systemImage: "star.fill")
                .font(.caption)
                .foregroundStyle(.orange)
        }
        .frame(width: 150)
    }
}
```

**Tareas:**
- [ ] Crear `MangaGridView` y `MangaGridCell`
- [ ] Añadir toggle List/Grid en ContentView
- [ ] Animar transición entre vistas
- [ ] Optimizar performance con lazy loading

---

### 3. Búsqueda Avanzada con Filtros Combinados

**Actualizar MangaViewModel:**
```swift
@Observable
final class MangaViewModel {
    var mangas: [Manga] = []
    var metadata: Metadata?
    var isLoading = false
    var errorMessage: String?
    var filters = MangaFilters() // Añadimos esto

    private let repository = NetworkRepository()

    func applyFilters() async {
        isLoading = true
        errorMessage = nil

        do {
            // Si hay filtros múltiples, usar POST /search/manga
            if filters.genres.count > 0 || filters.demographics.count > 0 || filters.themes.count > 0 {
                let customSearch = CustomSearch(
                    searchTitle: filters.searchText.isEmpty ? nil : filters.searchText,
                    searchAuthorFirstName: nil,
                    searchAuthorLastName: nil,
                    searchGenres: filters.genres.isEmpty ? nil : Array(filters.genres),
                    searchThemes: filters.themes.isEmpty ? nil : Array(filters.themes),
                    searchDemographics: filters.demographics.isEmpty ? nil : Array(filters.demographics),
                    searchContains: true
                )

                // Necesitamos implementar este método en Repository
                let response = try await repository.searchCustom(customSearch)
                mangas = response.items
                metadata = response.metadata
            }
            // Si solo hay un género, usar endpoint específico
            else if let genre = filters.genres.first {
                let response = try await repository.getMangasByGenre(genre)
                mangas = response.items
                metadata = response.metadata
            }
            // Si solo hay una demografía
            else if let demo = filters.demographics.first {
                let response = try await repository.getMangasByDemographic(demo)
                mangas = response.items
                metadata = response.metadata
            }
            // Si solo hay búsqueda por texto
            else if !filters.searchText.isEmpty {
                let response = try await repository.searchMangasContains(filters.searchText)
                mangas = response.items
                metadata = response.metadata
            }
            // Sin filtros, cargar todos
            else {
                let response = try await repository.getMangas()
                mangas = response.items
                metadata = response.metadata
            }

            // Aplicar ordenamiento local
            sortMangas(by: filters.sortBy)
        } catch {
            errorMessage = "Error al aplicar filtros: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func sortMangas(by option: MangaFilters.SortOption) {
        switch option {
        case .score:
            mangas.sort { $0.score > $1.score }
        case .title:
            mangas.sort { $0.title < $1.title }
        case .recent:
            mangas.sort { ($0.startDate ?? "") > ($1.startDate ?? "") }
        }
    }
}
```

**Añadir al NetworkRepository:**
```swift
func searchCustom(_ search: CustomSearch, page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga> {
    try await postJSON(.post(url: .searchManga.withPagination(page: page, per: per), body: search), type: PaginatedResponse<Manga>.self)
}
```

**Tareas:**
- [ ] Implementar `searchCustom` en NetworkRepository
- [ ] Actualizar MangaViewModel con lógica de filtros
- [ ] Añadir sorting local
- [ ] Testing de combinaciones de filtros

---

### 4. Toggle entre List y Grid

**En ContentView:**
```swift
struct ContentView: View {
    @State private var viewModel = MangaViewModel()
    @State private var showFilters = false
    @State private var viewMode: ViewMode = .list

    enum ViewMode {
        case list, grid
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.mangas.isEmpty {
                    ProgressView("Cargando mangas...")
                } else if let errorMessage = viewModel.errorMessage {
                    // Error view
                } else if viewModel.mangas.isEmpty {
                    // Empty view
                } else {
                    // Toggle entre List y Grid
                    switch viewMode {
                    case .list:
                        List(viewModel.mangas) { manga in
                            NavigationLink(value: manga) {
                                MangaRow(manga: manga)
                            }
                        }
                    case .grid:
                        MangaGridView(mangas: viewModel.mangas)
                    }
                }
            }
            .navigationTitle("Mis Mangas")
            .navigationDestination(for: Manga.self) { manga in
                MangaDetailView(manga: manga)
            }
            .toolbar {
                // Toggle List/Grid
                ToolbarItem(placement: .topBarLeading) {
                    Picker("Vista", selection: $viewMode) {
                        Image(systemName: "list.bullet").tag(ViewMode.list)
                        Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
                    }
                    .pickerStyle(.segmented)
                }

                // Botón de filtros
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: viewModel.filters.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterView(filters: $viewModel.filters)
            }
            .onChange(of: viewModel.filters) { oldValue, newValue in
                Task {
                    await viewModel.applyFilters()
                }
            }
        }
        .task {
            await viewModel.fetchMangas()
        }
    }
}
```

---

## 📦 Checklist de Entrega - Versión Media

### Funcionalidades Core
- [ ] Todo de versión básica completado
- [ ] Sistema completo de filtros (géneros, demos, temas)
- [ ] Combinación de múltiples filtros
- [ ] Búsqueda por texto
- [ ] Ordenamiento (score, título, fecha)
- [ ] Vista Grid con celdas optimizadas
- [ ] Toggle List/Grid con animación
- [ ] Indicador visual de filtros activos
- [ ] Limpiar filtros con un botón

### UI/UX
- [ ] FilterView con todos los filtros
- [ ] Búsqueda funcional
- [ ] Grid responsivo (iPad muestra más columnas)
- [ ] Animaciones entre cambios de vista
- [ ] Loading states durante filtrado
- [ ] Feedback visual al aplicar filtros

### Performance
- [ ] LazyVGrid para grid eficiente
- [ ] Debounce en búsqueda por texto
- [ ] Carga paginada en grid
- [ ] Caché de imágenes

---

## 🎯 Orden de Implementación Recomendado

### Día 1 - Sistema de Filtros
1. Crear `FilterModel` y `FilterViewModel`
2. Obtener listas de géneros/demos/temas
3. Crear UI de `FilterView`
4. Implementar toggles de filtros

### Día 2 - Integración de Filtros
1. Añadir `searchCustom` en Repository
2. Actualizar MangaViewModel con lógica de filtros
3. Integrar FilterView en ContentView
4. Testing de filtros simples y combinados

### Día 3 - Vista Grid
1. Crear `MangaGridView` y `MangaGridCell`
2. Implementar LazyVGrid
3. Añadir toggle List/Grid
4. Optimizar performance

### Día 4 - Polish y Búsqueda
1. Añadir búsqueda por texto
2. Implementar sorting
3. Animaciones y transiciones
4. Testing completo en iPhone/iPad

---

## 🚀 Mejoras Opcionales

1. **Filtros Persistentes**
   - Guardar filtros aplicados en UserDefaults
   - Restaurar al abrir app

2. **Historial de Búsqueda**
   - Guardar últimas búsquedas
   - Mostrar en FilterView

3. **Filtros Rápidos**
   - Chips con filtros predefinidos
   - "Top Rated", "Acción", "Shounen"

4. **Vista Compacta**
   - Tercera vista tipo "cover flow"
   - Solo portadas grandes

5. **Búsqueda por Autor**
   - Añadir campo de autor en FilterView
   - Usar `searchAuthorFirstName` y `searchAuthorLastName`

---

## ✨ Criterios de Éxito

La versión media estará completa cuando:

✅ Un usuario puede:
1. Aplicar filtros por género, demografía y tema (individuales o combinados)
2. Buscar mangas por texto
3. Ordenar resultados por diferentes criterios
4. Cambiar entre vista lista y grid
5. Ver claramente qué filtros están activos
6. Limpiar todos los filtros de una vez

✅ La UI:
1. Es fluida y responsiva
2. Tiene animaciones al cambiar vistas
3. Muestra feedback claro al filtrar
4. Funciona perfectamente en iPhone y iPad

✅ El código:
1. Mantiene Clean Architecture
2. Es eficiente (lazy loading, caché)
3. Es extensible para versión avanzada

---

**Anterior:** [← Versión Básica](versionBasica.md)
**Siguiente:** [Versión Avanzada →](versionAvanzada.md)
