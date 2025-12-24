# Guía de Accesibilidad para MisMangas

> **Objetivo:** Hacer que MisMangas sea 100% accesible para todos los usuarios, especialmente aquellos que usan VoiceOver, Dynamic Type y otras tecnologías de asistencia.

---

## 📋 Índice

1. [Introducción a la Accesibilidad](#introducción-a-la-accesibilidad)
2. [VoiceOver Support](#voiceover-support)
3. [Section Headers y Estructura Semántica](#section-headers-y-estructura-semántica)
4. [Dynamic Type](#dynamic-type)
5. [Contraste y Colores](#contraste-y-colores)
6. [Gestos y Navegación](#gestos-y-navegación)
7. [Ejemplos Prácticos para MisMangas](#ejemplos-prácticos-para-mismangas)
8. [Testing de Accesibilidad](#testing-de-accesibilidad)
9. [Checklist de Accesibilidad](#checklist-de-accesibilidad)

---

## 🌟 Introducción a la Accesibilidad

### ¿Por qué es importante?

- **15-20%** de la población tiene algún tipo de discapacidad
- Usuarios con discapacidad visual, motora, auditiva o cognitiva dependen de tecnologías de asistencia
- **Ley:** En muchos países es un requisito legal
- **UX mejorada:** Una app accesible es mejor para todos

### Pilares de la Accesibilidad en iOS

1. **VoiceOver** - Lector de pantalla
2. **Dynamic Type** - Tamaños de texto ajustables
3. **Contraste** - Colores diferenciables
4. **Navegación** - Estructura lógica y predecible
5. **Alternativas** - Texto alternativo para imágenes

---

## 🔊 VoiceOver Support

### ¿Qué es VoiceOver?

VoiceOver es el lector de pantalla de Apple que lee en voz alta el contenido de la pantalla. Los usuarios navegan con gestos y escuchan descripciones de cada elemento.

### Modificadores Esenciales

#### 1. `.accessibilityLabel()`
**Propósito:** Describe QUÉ es el elemento

```swift
// ❌ Malo - Label no descriptivo
Image(systemName: "star.fill")

// ✅ Bueno - Label claro
Image(systemName: "star.fill")
    .accessibilityLabel("Puntuación")
```

#### 2. `.accessibilityValue()`
**Propósito:** Describe el VALOR actual del elemento

```swift
// ✅ Ejemplo: Puntuación de manga
HStack {
    Image(systemName: "star.fill")
    Text("\(manga.score)")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Puntuación")
.accessibilityValue("\(String(format: "%.2f", manga.score)) de 10")
```

#### 3. `.accessibilityHint()`
**Propósito:** Describe QUÉ HACE el elemento cuando interactúas con él

```swift
// ✅ Ejemplo: Botón de añadir a colección
Button {
    addToCollection()
} label: {
    Label("Añadir", systemImage: "plus.circle")
}
.accessibilityLabel("Añadir a colección")
.accessibilityHint("Doble toque para añadir este manga a tu colección")
```

#### 4. `.accessibilityElement(children:)`
**Propósito:** Combina múltiples elementos en uno solo

```swift
// ✅ Ejemplo: Fila de manga
HStack {
    AsyncImage(url: URL(string: manga.mainPicture))
        .frame(width: 60, height: 90)

    VStack(alignment: .leading) {
        Text(manga.title)
            .font(.headline)
        Text("Vol. \(manga.volumes ?? 0)")
            .font(.caption)
    }
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(manga.title), \(manga.volumes ?? 0) volúmenes")
```

#### 5. `.accessibilityAddTraits()` / `.accessibilityRemoveTraits()`
**Propósito:** Indica el TIPO de elemento

Traits disponibles:
- `.isButton` - Es un botón
- `.isHeader` - Es un encabezado
- `.isLink` - Es un enlace
- `.isImage` - Es una imagen
- `.isSelected` - Está seleccionado
- `.allowsDirectInteraction` - Permite interacción directa
- `.updatesFrequently` - Se actualiza frecuentemente

```swift
// ✅ Ejemplo: Título de sección
Text("Explorar Mangas")
    .font(.largeTitle.bold())
    .accessibilityAddTraits(.isHeader)

// ✅ Ejemplo: Card clickable
VStack {
    // Contenido
}
.accessibilityAddTraits(.isButton)
.accessibilityLabel("Manga: \(manga.title)")
.accessibilityHint("Doble toque para ver detalles")
```

#### 6. `.accessibilityHidden()`
**Propósito:** Oculta elementos decorativos

```swift
// ✅ Ejemplo: Imagen decorativa
Image(systemName: "books.vertical")
    .accessibilityHidden(true) // VoiceOver lo ignora
```

#### 7. `.accessibilitySortPriority()`
**Propósito:** Controla el orden de lectura

```swift
VStack {
    Text("Título importante")
        .accessibilitySortPriority(2) // Se lee primero

    Text("Subtítulo")
        .accessibilitySortPriority(1) // Se lee después
}
```

---

## 📑 Section Headers y Estructura Semántica

### ¿Por qué son importantes los headers?

Los headers permiten a los usuarios de VoiceOver:
- **Navegar rápidamente** entre secciones (rotor de VoiceOver)
- **Entender la jerarquía** del contenido
- **Saltar información** no relevante

### Cómo implementar headers correctamente

#### Nivel 1: Títulos principales de pantalla

```swift
struct ContentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                // Contenido
            }
            .navigationTitle("Explorar Mangas") // Automáticamente es header nivel 1
        }
    }
}
```

#### Nivel 2: Secciones principales

```swift
VStack(alignment: .leading) {
    Text("Mejor Valorados")
        .font(.title2.bold())
        .accessibilityAddTraits(.isHeader)
        .accessibilityHeading(.h2) // iOS 17+

    // Contenido de la sección
}
```

#### Nivel 3: Subsecciones

```swift
VStack(alignment: .leading) {
    Text("Géneros")
        .font(.headline)
        .accessibilityAddTraits(.isHeader)
        .accessibilityHeading(.h3) // iOS 17+

    // Lista de géneros
}
```

### Ejemplo completo: MangaDetailView

```swift
struct MangaDetailView: View {
    let manga: Manga

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Imagen (decorativa, tiene alt text en content)
                AsyncImage(url: URL(string: manga.mainPicture))
                    .accessibilityLabel("Portada de \(manga.title)")

                // H1: Título del manga (NavigationTitle)

                // H2: Información Principal
                VStack(alignment: .leading, spacing: 12) {
                    Text("Información")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)

                    statsView
                }

                // H2: Autores
                VStack(alignment: .leading, spacing: 12) {
                    Text("Autores")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)

                    authorsView
                }

                // H2: Géneros y Categorías
                VStack(alignment: .leading, spacing: 12) {
                    Text("Categorías")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)

                    // H3: Géneros
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Géneros")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityHeading(.h3)

                        genresView
                    }

                    // H3: Temas
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Temas")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityHeading(.h3)

                        themesView
                    }
                }

                // H2: Sinopsis
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sinopsis")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)

                    Text(manga.sypnosis ?? "")
                }
            }
            .padding()
        }
        .navigationTitle(manga.title) // H1 automático
    }
}
```

### Navegación con VoiceOver Rotor

Los usuarios pueden:
1. Activar el rotor (giro con 2 dedos)
2. Seleccionar "Encabezados"
3. Deslizar arriba/abajo para saltar entre headers

---

## 📏 Dynamic Type

### ¿Qué es Dynamic Type?

Permite a los usuarios ajustar el tamaño del texto en Settings → Accessibility → Display & Text Size.

### Tamaños de Dynamic Type

```
xSmall → Small → Medium → Large (Default) →
xLarge → xxLarge → xxxLarge →
Accessibility Medium → Accessibility Large →
Accessibility Extra Large → Accessibility XXL → Accessibility XXXL
```

### Implementación correcta

#### ✅ Usar estilos de texto semánticos

```swift
// ✅ BUENO - Se adapta automáticamente
Text("Título")
    .font(.title)

Text("Cuerpo")
    .font(.body)

Text("Caption")
    .font(.caption)

// ❌ MALO - Tamaño fijo
Text("Título")
    .font(.system(size: 24)) // No se adapta!
```

#### ✅ Usar estilos personalizados con Dynamic Type

```swift
// ✅ Usar .relative para mantener escalado
Text("Custom")
    .font(.system(size: 20, weight: .bold, design: .rounded))
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge) // Limitar tamaño máximo si es necesario
```

#### ✅ Layouts flexibles

```swift
// ✅ BUENO - Layout adaptativo
VStack(alignment: .leading) {
    Text("Título")
        .font(.headline)
    Text("Subtítulo")
        .font(.subheadline)
}
.frame(maxWidth: .infinity, alignment: .leading)

// ❌ MALO - Ancho fijo
VStack {
    Text("Título")
        .frame(width: 200) // Puede truncar texto grande
}
```

#### ✅ ViewThatFits para tamaños grandes

```swift
ViewThatFits {
    // Layout horizontal (texto pequeño)
    HStack {
        Image(systemName: "star.fill")
        Text("Puntuación: \(manga.score)")
    }

    // Layout vertical (texto grande)
    VStack(alignment: .leading) {
        Image(systemName: "star.fill")
        Text("Puntuación: \(manga.score)")
    }
}
```

### Limitar tamaños cuando sea necesario

```swift
Text("Título")
    .font(.title)
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge) // Limitar a xxxLarge
```

### Probar Dynamic Type

En Xcode:
1. **Simulador:** Settings → Accessibility → Larger Text
2. **Xcode Previews:**
   ```swift
   #Preview {
       ContentView()
           .environment(\.dynamicTypeSize, .accessibility5)
   }
   ```

---

## 🎨 Contraste y Colores

### Ratios de contraste mínimos (WCAG)

- **Texto normal:** 4.5:1
- **Texto grande (18pt+):** 3:1
- **Elementos UI:** 3:1

### Herramientas para verificar contraste

- **Online:** [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- **macOS:** Accessibility Inspector (Xcode → Open Developer Tool)

### Implementación

#### ✅ Usar colores semánticos del sistema

```swift
// ✅ BUENO - Se adapta a modo claro/oscuro
Text("Título")
    .foregroundStyle(.primary) // Negro en claro, blanco en oscuro

Text("Subtítulo")
    .foregroundStyle(.secondary)

Button("Acción") { }
    .foregroundStyle(.blue) // Color del sistema con contraste garantizado
```

#### ✅ Respetar configuración de contraste alto

```swift
@Environment(\.colorSchemeContrast) private var contrast

var textColor: Color {
    contrast == .increased ? .black : .primary
}

Text("Texto")
    .foregroundStyle(textColor)
```

#### ✅ No usar solo color para transmitir información

```swift
// ❌ MALO - Solo color
Circle()
    .fill(manga.status == "finished" ? .green : .red)

// ✅ BUENO - Color + icono/texto
HStack {
    Image(systemName: manga.status == "finished" ? "checkmark.circle.fill" : "clock.fill")
    Text(manga.status == "finished" ? "Finalizado" : "En emisión")
}
.foregroundStyle(manga.status == "finished" ? .green : .orange)
```

---

## 👆 Gestos y Navegación

### Área táctil mínima

**Tamaño mínimo recomendado:** 44x44 puntos

```swift
// ✅ BUENO
Button("Acción") { }
    .frame(minWidth: 44, minHeight: 44)

// ❌ MALO
Button("X") { }
    .frame(width: 20, height: 20) // Muy pequeño
```

### Focus y Tab Navigation

```swift
// Controlar el orden del focus
VStack {
    TextField("Nombre", text: $name)
        .accessibilityLabel("Nombre de usuario")

    TextField("Email", text: $email)
        .accessibilityLabel("Correo electrónico")

    Button("Registrar") { }
}
```

### Acciones personalizadas de accesibilidad

```swift
// Añadir acciones accesibles a elementos
VStack {
    Text(manga.title)
}
.accessibilityElement(children: .combine)
.accessibilityLabel(manga.title)
.accessibilityAction(named: "Añadir a colección") {
    addToCollection()
}
.accessibilityAction(named: "Compartir") {
    share()
}
```

---

## 💡 Ejemplos Prácticos para MisMangas

### 1. MangaRow (Lista)

```swift
struct MangaRow: View {
    let manga: Manga

    var body: some View {
        HStack(spacing: 12) {
            // Imagen de portada
            AsyncImage(url: URL(string: manga.mainPicture)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityHidden(true) // Imagen decorativa, info está en el label

            VStack(alignment: .leading, spacing: 4) {
                Text(manga.title)
                    .font(.headline)

                // Puntuación
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .accessibilityHidden(true) // Decorativo

                    Text(String(format: "%.2f", manga.score))
                        .font(.subheadline)
                }

                // Géneros
                if !manga.genres.isEmpty {
                    Text(manga.genres.prefix(3).map(\.genre).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        // Combinar todo en un solo elemento accesible
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibleLabel)
        .accessibilityHint("Doble toque para ver detalles completos")
        .accessibilityAddTraits(.isButton)
    }

    private var accessibleLabel: String {
        var label = manga.title
        label += ", puntuación \(String(format: "%.1f", manga.score)) de 10"

        if let volumes = manga.volumes {
            label += ", \(volumes) volúmenes"
        }

        if !manga.genres.isEmpty {
            let genreNames = manga.genres.prefix(3).map(\.genre).joined(separator: ", ")
            label += ", géneros: \(genreNames)"
        }

        return label
    }
}
```

### 2. MangaDetailView Headers

```swift
struct MangaDetailView: View {
    let manga: Manga

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Portada
                AsyncImage(url: URL(string: manga.mainPicture))
                    .frame(height: 400)
                    .accessibilityLabel("Portada de \(manga.title)")

                // Stats compactos
                statsSection

                // Autores
                authorsSection

                // Categorías
                categoriesSection

                // Sinopsis
                synopsisSection
            }
            .padding()
        }
        .navigationTitle(manga.title) // H1
        .navigationBarTitleDisplayMode(.large)
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Información")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)

            HStack(spacing: 20) {
                // Puntuación
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .accessibilityHidden(true)
                        Text(String(format: "%.2f", manga.score))
                            .font(.title.bold())
                    }
                    Text("Puntuación")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Puntuación \(String(format: "%.2f", manga.score)) de 10")

                // Volúmenes
                if let volumes = manga.volumes {
                    VStack(alignment: .leading) {
                        Text("\(volumes)")
                            .font(.title.bold())
                        Text("Volúmenes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(volumes) volúmenes en total")
                }

                // Estado
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: statusIcon)
                            .foregroundStyle(statusColor)
                        Text(manga.status.capitalized)
                            .font(.headline)
                    }
                    Text("Estado")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Estado: \(manga.status == "finished" ? "Finalizado" : "En emisión")")
            }
        }
    }

    private var authorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Autores")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)

            ForEach(manga.authors) { author in
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading) {
                        Text("\(author.firstName) \(author.lastName)")
                            .font(.headline)
                        Text(author.role)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(author.firstName) \(author.lastName), \(author.role)")
            }
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categorías")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)

            // Géneros
            if !manga.genres.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Géneros")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h3)

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
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Géneros: \(manga.genres.map(\.genre).joined(separator: ", "))")
                }
            }

            // Temas
            if !manga.themes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Temas")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h3)

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
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Temas: \(manga.themes.map(\.theme).joined(separator: ", "))")
                }
            }
        }
    }

    private var synopsisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sinopsis")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)

            Text(manga.sypnosis ?? "Sin sinopsis disponible")
                .font(.body)
        }
    }

    private var statusIcon: String {
        manga.status == "finished" ? "checkmark.circle.fill" : "clock.fill"
    }

    private var statusColor: Color {
        manga.status == "finished" ? .green : .orange
    }
}
```

### 3. FilterView (Accesible)

```swift
struct FilterView: View {
    @Environment(FilterViewModel.self) private var filterVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Géneros
                Section {
                    ForEach(filterVM.availableGenres) { genre in
                        Toggle(genre.genre, isOn: bindingForGenre(genre))
                    }
                } header: {
                    Text("Géneros")
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                }

                // Demografía
                Section {
                    ForEach(filterVM.availableDemographics) { demo in
                        Toggle(demo.demographic, isOn: bindingForDemo(demo))
                    }
                } header: {
                    Text("Demografía")
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                }

                // Temas
                Section {
                    ForEach(filterVM.availableThemes) { theme in
                        Toggle(theme.theme, isOn: bindingForTheme(theme))
                    }
                } header: {
                    Text("Temas")
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                }
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Limpiar") {
                        filterVM.clearFilters()
                    }
                    .accessibilityLabel("Limpiar todos los filtros")
                    .accessibilityHint("Doble toque para desmarcar todos los filtros")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Aplicar") {
                        dismiss()
                    }
                    .accessibilityLabel("Aplicar filtros")
                    .accessibilityHint("Doble toque para aplicar los filtros seleccionados y cerrar")
                }
            }
        }
    }
}
```

### 4. AddToCollectionView

```swift
struct AddToCollectionView: View {
    let manga: Manga
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.dismiss) private var dismiss

    @State private var volumesOwned: Int = 1
    @State private var readingVolume: Int = 1
    @State private var completeCollection: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                // Volúmenes propios
                Section {
                    Stepper(
                        value: $volumesOwned,
                        in: 1...(manga.volumes ?? 999)
                    ) {
                        HStack {
                            Text("Volúmenes que poseo")
                            Spacer()
                            Text("\(volumesOwned)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("Volúmenes que poseo")
                    .accessibilityValue("\(volumesOwned) de \(manga.volumes ?? 0)")
                    .accessibilityHint("Deslizar hacia arriba para incrementar, hacia abajo para decrementar")
                } header: {
                    Text("Progreso de Colección")
                        .accessibilityAddTraits(.isHeader)
                }

                // Volumen actual de lectura
                Section {
                    Stepper(
                        value: $readingVolume,
                        in: 1...volumesOwned
                    ) {
                        HStack {
                            Text("Volumen actual")
                            Spacer()
                            Text("\(readingVolume)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("Volumen de lectura actual")
                    .accessibilityValue("Volumen \(readingVolume)")
                    .accessibilityHint("Deslizar hacia arriba para incrementar, hacia abajo para decrementar")

                    ProgressView(value: Double(readingVolume), total: Double(manga.volumes ?? 1))
                        .accessibilityLabel("Progreso de lectura")
                        .accessibilityValue("\(Int((Double(readingVolume) / Double(manga.volumes ?? 1)) * 100)) por ciento completado")
                } header: {
                    Text("Progreso de Lectura")
                        .accessibilityAddTraits(.isHeader)
                }

                // Colección completa
                Section {
                    Toggle("Tengo la colección completa", isOn: $completeCollection)
                        .onChange(of: completeCollection) { _, newValue in
                            if newValue {
                                volumesOwned = manga.volumes ?? 1
                            }
                        }
                }

                // Botón guardar
                Section {
                    Button {
                        Task {
                            await saveToCollection()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if cloudVM.isLoading {
                                ProgressView()
                            } else {
                                Text("Añadir a Colección")
                                    .font(.headline)
                            }
                            Spacer()
                        }
                    }
                    .disabled(cloudVM.isLoading)
                    .accessibilityLabel("Añadir a colección")
                    .accessibilityHint("Doble toque para guardar este manga en tu colección")
                }
            }
            .navigationTitle("Añadir a Colección")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveToCollection() async {
        do {
            try await cloudVM.addToCollection(
                manga: manga,
                volumesOwned: volumesOwned,
                readingVolume: readingVolume,
                completeCollection: completeCollection
            )
            dismiss()
        } catch {
            print("Error: \(error)")
        }
    }
}
```

---

## 🧪 Testing de Accesibilidad

### 1. Usar Accessibility Inspector (Xcode)

**Pasos:**
1. Xcode → Open Developer Tool → Accessibility Inspector
2. Seleccionar simulador o dispositivo
3. Inspeccionar elementos
4. Ver warnings y errors
5. Ejecutar audit completo

### 2. Probar con VoiceOver real

**iOS:**
- Settings → Accessibility → VoiceOver → ON
- O triple-click botón lateral (si está configurado)

**Gestos básicos:**
- **Deslizar derecha/izquierda:** Navegar elementos
- **Doble toque:** Activar elemento
- **Giro con 2 dedos:** Rotor (cambiar modo navegación)
- **3 dedos swipe arriba/abajo:** Scroll

**macOS:**
- System Settings → Accessibility → VoiceOver → ON
- O Cmd+F5

### 3. Audit de accesibilidad en Previews

```swift
#Preview {
    MangaDetailView(manga: .test)
        .environment(\.accessibilityEnabled, true)
}

#Preview("VoiceOver") {
    MangaDetailView(manga: .test)
        .environment(\.accessibilityDifferentiateWithoutColor, true)
        .environment(\.accessibilityReduceTransparency, true)
}

#Preview("Large Text") {
    MangaDetailView(manga: .test)
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("High Contrast") {
    MangaDetailView(manga: .test)
        .environment(\.colorSchemeContrast, .increased)
}
```

### 4. UI Tests de accesibilidad

```swift
func testMangaRowAccessibility() {
    let app = XCUIApplication()
    app.launch()

    let mangaRow = app.buttons.matching(identifier: "MangaRow").firstMatch
    XCTAssertTrue(mangaRow.exists)

    // Verificar que tiene label
    XCTAssertFalse(mangaRow.label.isEmpty)

    // Verificar que es accesible
    XCTAssertTrue(mangaRow.isAccessibilityElement)

    // Verificar traits
    XCTAssertTrue(mangaRow.traits.contains(.button))
}
```

---

## ✅ Checklist de Accesibilidad

### General
- [ ] Todas las imágenes decorativas tienen `.accessibilityHidden(true)`
- [ ] Todas las imágenes informativas tienen `.accessibilityLabel()`
- [ ] Todos los botones tienen labels descriptivos
- [ ] Todos los iconos tienen labels o están marcados como decorativos
- [ ] No se usa solo color para transmitir información

### VoiceOver
- [ ] Todos los elementos interactivos son accesibles
- [ ] Los labels son claros y concisos
- [ ] Se usan hints cuando la acción no es obvia
- [ ] Los elementos complejos se combinan con `.accessibilityElement(children: .combine)`
- [ ] Los traits son correctos (`.isButton`, `.isHeader`, etc.)
- [ ] El orden de lectura es lógico

### Section Headers
- [ ] NavigationTitle para H1
- [ ] Títulos de sección principales marcados como H2
- [ ] Subsecciones marcadas como H3
- [ ] Headers tienen `.accessibilityAddTraits(.isHeader)`
- [ ] Headers tienen `.accessibilityHeading(.h2/.h3)` (iOS 17+)
- [ ] Jerarquía de headers es lógica y consistente

### Dynamic Type
- [ ] Se usan estilos de texto semánticos (`.font(.body)`, etc.)
- [ ] Layouts son flexibles y no tienen anchos fijos
- [ ] Probado con tamaños Accessibility XXL y XXXL
- [ ] ViewThatFits usado para layouts complejos
- [ ] Se limita Dynamic Type solo cuando es absolutamente necesario

### Contraste y Color
- [ ] Textos tienen contraste mínimo 4.5:1
- [ ] Elementos UI tienen contraste mínimo 3:1
- [ ] Se usan colores del sistema cuando es posible
- [ ] Probado en modo claro y oscuro
- [ ] Probado con contraste aumentado
- [ ] Iconos + texto para estados (no solo color)

### Navegación
- [ ] Áreas táctiles mínimas de 44x44pt
- [ ] Tab order es lógico
- [ ] Acciones personalizadas donde sea apropiado
- [ ] Feedback háptico en watchOS
- [ ] Mensajes de error son claros y accesibles

### Testing
- [ ] Probado con VoiceOver activado
- [ ] Probado con Dynamic Type en tamaños grandes
- [ ] Probado con contraste aumentado
- [ ] Probado con reducción de transparencia
- [ ] Audit con Accessibility Inspector
- [ ] UI Tests de accesibilidad implementados

---

## 📚 Recursos Adicionales

### Documentación Oficial

- [Apple Accessibility HIG](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [SwiftUI Accessibility](https://developer.apple.com/documentation/swiftui/view-accessibility)
- [WWDC Videos - Accessibility](https://developer.apple.com/videos/accessibility)

### Guías y Estándares

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [iOS Accessibility Best Practices](https://developer.apple.com/accessibility/ios/)

### Herramientas

- Accessibility Inspector (Xcode)
- Color Contrast Analyzer
- VoiceOver (iOS/macOS)
- Accessibility Rotor

---

## 🎯 Resumen

Para hacer MisMangas 100% accesible:

1. **VoiceOver:** Labels claros, hints útiles, traits correctos
2. **Headers:** Estructura semántica con H1, H2, H3
3. **Dynamic Type:** Fuentes semánticas, layouts flexibles
4. **Contraste:** Colores del sistema, verificar ratios
5. **Testing:** Probar con tecnologías de asistencia reales

**Recuerda:** La accesibilidad no es opcional, es esencial para una experiencia de usuario completa.

---

**Última actualización:** 13 de Diciembre, 2025
**Autor:** Claude + Juan Carlos
