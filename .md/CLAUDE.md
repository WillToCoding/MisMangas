# MisMangas - Roadmap del Proyecto

> **Desarrollado con:** Swift 6.0, iOS 17+, Clean Architecture, MVVM
> **Principios:** Solo librerías de Apple, async/await, Sendable, SwiftUI moderno
> **Plataformas:** iOS, macOS, watchOS, tvOS, visionOS

---

## 📋 Índice

1. [Arquitectura del Proyecto](#arquitectura-del-proyecto)
2. [Estado Actual](#estado-actual)
3. [Plataformas Soportadas](#plataformas-soportadas)
4. [Roadmap por Versiones](#roadmap-por-versiones)
5. [Estructura de Carpetas](#estructura-de-carpetas)
6. [Convenciones y Buenas Prácticas](#convenciones-y-buenas-prácticas)

---

## 🏗️ Arquitectura del Proyecto

### Clean Architecture + MVVM

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│   (Views + ViewModels + Components) │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│         Domain Layer                │
│         (Models/DTOs)               │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│           Data Layer                │
│  (Network + Repository + Storage)   │
└─────────────────────────────────────┘
```

### Capas del Proyecto

**1. Presentation Layer**
- `Views/` - Vistas SwiftUI (iOS)
- `MisMangas macOS/Views/` - Vistas macOS específicas
- `MisMangas watchOS/` - Vistas watchOS
- `MisMangas tvOS/Views/` - Vistas tvOS (planificadas)
- `MisMangas visionOS/Views/` - Vistas visionOS (planificadas)
- `Components/` - Componentes reutilizables
- `ViewModel/` - Lógica de presentación (@Observable)

**2. Domain Layer**
- `Model/` - DTOs y estructuras de datos compartidas
- `DataModel/` - Modelos SwiftData (iOS persistencia local)

**3. Data Layer**
- `Network/` - NetworkRepository, URL extensions
- `Storage/` - KeychainHelper (tokens seguros)

---

## ✅ Estado Actual

### Versión: **Avanzada/Deluxe** (Ecosistema Multi-plataforma)

### iOS - COMPLETADO ✅

**Autenticación**
- [x] `LoginView.swift` - Pantalla de login
- [x] `RegisterView.swift` - Registro de usuarios
- [x] `AuthViewModel.swift` - Gestión de autenticación
- [x] `AuthError.swift` - Manejo de errores
- [x] `KeychainHelper.swift` - Almacenamiento seguro de tokens

**Navegación y Estructura**
- [x] `MainTabView.swift` - TabView principal con navegación
- [x] `ContentView.swift` - Vista principal de exploración
- [x] `ProfileView.swift` - Perfil de usuario

**Exploración de Mangas**
- [x] `MangaGridView.swift` - Vista en grid
- [x] `MangaDetailView.swift` - Detalle completo de manga
- [x] `MangaRow.swift` - Componente de fila reutilizable
- [x] `MangaViewModel.swift` - Lógica de negocio
- [x] Búsqueda de mangas
- [x] Paginación implementada

**Filtros**
- [x] `FilterView.swift` - Vista de filtros
- [x] `FilterViewModel.swift` - Lógica de filtros
- [x] `FilterModel.swift` - Modelos de filtros
- [x] Filtros por género, demografía, temas

**Colecciones**
- [x] `CollectionView.swift` - Vista de colección del usuario
- [x] `AddToCollectionView.swift` - Añadir manga a colección
- [x] `CloudCollectionViewModel.swift` - Gestión de colección cloud
- [x] Sincronización con servidor
- [x] SwiftData para persistencia local

**Modelos y Data**
- [x] `ModelDTO.swift` - DTOs completos (Manga, Author, Genre, Theme, etc.)
- [x] `Model.swift` - Modelos SwiftData
- [x] `PreviewData.swift` - Datos de prueba
- [x] `ModelContainer+Extension.swift` - Extensiones para previews

**Network**
- [x] `NetworkRepository.swift` - Repository pattern con NetworkAPI
- [x] `URL.swift` - URLs y endpoints
- [x] Integración con API REST
- [x] Manejo de errores robusto

### macOS - COMPLETADO ✅

**Estructura Principal**
- [x] `MacMainView.swift` - NavigationSplitView (3 columnas)
- [x] `MisMangas_macOSApp.swift` - Entry point
- [x] Menús nativos macOS
- [x] Keyboard shortcuts
- [x] Toolbar personalizado

**Vistas Específicas macOS**
- [x] `MacSidebarView.swift` - Sidebar de navegación
- [x] `MacMangaListView.swift` - Lista de mangas
- [x] `MacMangaRow.swift` - Fila optimizada para Mac
- [x] `MacMangaDetailView.swift` - Detalle con layout grande
- [x] `MacCollectionView.swift` - Colección del usuario
- [x] `MacLoginView.swift` - Login nativo macOS
- [x] `MacRegisterView.swift` - Registro nativo macOS
- [x] `MacPreferencesView.swift` - Ventana de preferencias

**Características macOS**
- [x] NavigationSplitView con 3 columnas
- [x] Búsqueda y filtros avanzados
- [x] Vista optimizada para pantalla grande
- [x] Compartir ViewModels con iOS

### watchOS - COMPLETADO ✅

**Estructura**
- [x] `MisMangas_watchOSApp.swift` - Entry point
- [x] App Groups configurados para compartir tokens
- [x] KeychainHelper compartido

**Vistas watchOS**
- [x] `WatchRootView.swift` - Vista principal
- [x] `WatchCollectionView.swift` - Lista de colección
- [x] `WatchMangaRow.swift` - Fila compacta para Watch
- [x] `WatchMangaDetailView.swift` - Detalle con actualización de progreso

**Características watchOS**
- [x] Ver colección desde la nube
- [x] Actualizar volumen de lectura
- [x] Sincronización con servidor
- [x] Feedback háptico
- [x] UI optimizada para pantalla pequeña

### tvOS - PLANIFICADO 📋

**Estado:** Plan completo en `tvOS-plan.md`

**Características Planeadas:**
- Grid grande optimizado para TV (10ft UI)
- Navegación con Siri Remote (Focus Engine)
- Textos y elementos grandes
- Actualización de progreso de lectura
- Parallax effects

### visionOS - PLANIFICADO 📋

**Estado:** Plan completo en `visionOS-plan.md`

**Características Planeadas:**
- UI espacial con ventanas 3D
- Navegación con gestos y mirada
- Ornaments (controles flotantes)
- Modo inmersivo opcional
- Grid de mangas en el espacio

### Pendiente (Mejoras Futuras)

- [ ] Widget estático (WidgetKit)
- [ ] Handoff entre dispositivos
- [ ] Shortcuts/Siri integration
- [ ] CloudKit sync opcional
- [ ] Tests unitarios completos
- [ ] Tests de integración

---

## 🌐 Plataformas Soportadas

### iOS (17+)
**Estado:** ✅ Completo
- App completa con todas las funcionalidades
- SwiftData para persistencia local
- Autenticación y colecciones cloud
- Filtros, búsqueda, navegación

### macOS (14.0+)
**Estado:** ✅ Completo
- NavigationSplitView optimizado
- Menús nativos y keyboard shortcuts
- UI optimizada para pantalla grande
- Compartir datos con iOS

### watchOS (10.0+)
**Estado:** ✅ Completo
- Ver colección desde Apple Watch
- Actualizar progreso de lectura
- Sincronización con cloud
- App Groups para compartir tokens

### tvOS
**Estado:** 📋 Planificado
- Ver plan completo: `.md/tvOS-plan.md`

### visionOS
**Estado:** 📋 Planificado
- Ver plan completo: `.md/visionOS-plan.md`

---

## 🎯 Roadmap por Versiones

### ✅ [Versión Básica](versionBasica.md) - COMPLETADA
**Objetivo:** App funcional con lectura de API y persistencia local

**Funcionalidades Core:**
- ✅ Consulta de mangas desde API
- ✅ Vista detalle de manga
- ✅ Filtrado por géneros/demografía/temas
- ✅ Guardar manga en colección local (SwiftData)
- ✅ Mostrar colección del usuario
- ✅ Layout adaptativo iPhone/iPad

---

### ✅ [Versión Media](versionMedia.md) - COMPLETADA
**Objetivo:** Experiencia completa con filtros y múltiples vistas

**Funcionalidades:**
- ✅ Filtros completos (géneros, demografías, temas)
- ✅ Grid view de mangas
- ✅ Búsqueda de mangas
- ✅ Animaciones y transiciones
- ✅ Pull-to-refresh
- ✅ Estados de loading/error/empty

---

### ✅ [Versión Avanzada](versionAvanzada.md) - COMPLETADA
**Objetivo:** App cloud-first con autenticación

**Funcionalidades:**
- ✅ Sistema de login/registro
- ✅ Gestión de colección en la nube
- ✅ Keychain para almacenar tokens
- ✅ Sincronización local/remota
- ✅ Renovación automática de tokens
- ✅ Perfil de usuario

---

### 🚧 [Versión Deluxe](versionDeluxe.md) - EN PROGRESO
**Objetivo:** Ecosistema Apple completo

**Funcionalidades:**
- ✅ Soporte para macOS (completo)
- ✅ Soporte para watchOS (completo)
- 📋 Soporte para tvOS (planificado)
- 📋 Soporte para visionOS (planificado)
- ⏳ Widget estático (WidgetKit)
- ⏳ Handoff entre dispositivos
- ⏳ Shortcuts/Siri integration
- ⏳ CloudKit sync (opcional)

---

## 📁 Estructura de Carpetas

```
MisMangas/
├── .md/                          # Documentación del proyecto
│   ├── CLAUDE.md                 # Este archivo (roadmap principal)
│   ├── versionBasica.md          # Plan versión básica
│   ├── versionMedia.md           # Plan versión media
│   ├── versionAvanzada.md        # Plan versión avanzada
│   ├── versionDeluxe.md          # Plan versión deluxe
│   ├── macOS-plan.md             # Plan implementación macOS
│   ├── watchOS-plan.md           # Plan implementación watchOS
│   ├── tvOS-plan.md              # Plan implementación tvOS
│   └── visionOS-plan.md          # Plan implementación visionOS
│
├── MisMangas/                    # Target iOS
│   ├── System/
│   │   └── MisMangasApp.swift    # Entry point iOS
│   │
│   ├── Views/                    # Vistas iOS
│   │   ├── MainTabView.swift     # TabView principal
│   │   ├── ContentView.swift     # Exploración de mangas
│   │   ├── LoginView.swift       # Login
│   │   ├── RegisterView.swift    # Registro
│   │   ├── ProfileView.swift     # Perfil
│   │   ├── MangaGridView.swift   # Grid de mangas
│   │   ├── MangaDetailView.swift # Detalle de manga
│   │   ├── FilterView.swift      # Filtros
│   │   ├── CollectionView.swift  # Colección del usuario
│   │   └── AddToCollectionView.swift # Añadir a colección
│   │
│   ├── Components/               # Componentes reutilizables
│   │   └── MangaRow.swift        # Fila de manga
│   │
│   ├── ViewModel/                # ViewModels (compartidos)
│   │   ├── MangaViewModel.swift
│   │   ├── AuthViewModel.swift
│   │   ├── FilterViewModel.swift
│   │   └── CloudCollectionViewModel.swift
│   │
│   ├── Model/                    # Domain Layer (compartido)
│   │   ├── ModelDTO.swift        # DTOs de la API
│   │   ├── AuthError.swift       # Errores de autenticación
│   │   └── FilterModel.swift     # Modelos de filtros
│   │
│   ├── DataModel/                # SwiftData (solo iOS)
│   │   ├── Model.swift           # Modelos SwiftData
│   │   ├── PreviewData.swift     # Datos de prueba
│   │   └── ModelContainer+Extension.swift
│   │
│   ├── Network/                  # Data Layer (compartido)
│   │   ├── URL.swift             # URLs y endpoints
│   │   └── NetworkRepository.swift
│   │
│   ├── Storage/                  # Storage (compartido)
│   │   └── KeychainHelper.swift  # Tokens seguros
│   │
│   └── Resources/
│       └── Práctica _Mis Mangas_, SDP.pdf
│
├── MisMangas macOS/              # Target macOS
│   ├── System/
│   │   └── MisMangas_macOSApp.swift
│   │
│   ├── MacMainView.swift         # NavigationSplitView principal
│   │
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
│   │   ├── Auth/
│   │   │   ├── MacLoginView.swift
│   │   │   └── MacRegisterView.swift
│   │   └── MacPreferencesView.swift
│   │
│   └── Assets.xcassets/
│
├── MisMangas watchOS Watch App/  # Target watchOS
│   ├── System/
│   │   └── MisMangas_watchOSApp.swift
│   │
│   ├── WatchRootView.swift       # Vista principal
│   ├── WatchCollectionView.swift # Colección
│   ├── WatchMangaRow.swift       # Fila compacta
│   ├── WatchMangaDetailView.swift # Detalle + actualizar progreso
│   │
│   └── Assets.xcassets/
│
├── MisMangas tvOS/               # Target tvOS (planificado)
│   └── (pendiente de implementar)
│
├── MisMangas visionOS/           # Target visionOS (planificado)
│   └── (pendiente de implementar)
│
└── MisMangas.xcodeproj/
```

---

## 🎨 Convenciones y Buenas Prácticas

### Código

1. **Nombres claros y descriptivos**
   ```swift
   // ✅ Bueno
   func fetchMangas(page: Int = 1, per: Int = 10) async throws -> PaginatedResponse<Manga>

   // ❌ Malo
   func getM(p: Int) async throws -> Data
   ```

2. **Return implícito en funciones de una línea**
   ```swift
   // ✅ Bueno
   func getMangas() async throws -> [Manga] {
       try await getJSON(.get(url: .listMangas), type: [Manga].self)
   }
   ```

3. **@Observable para ViewModels** (no @ObservableObject)
   ```swift
   @Observable
   final class MangaViewModel { }
   ```

4. **Async/await** (no Combine ni callbacks)
   ```swift
   // ✅ Bueno
   await viewModel.fetchMangas()

   // ❌ Evitar
   viewModel.fetchMangas { result in }
   ```

5. **Sendable para tipos concurrentes**
   ```swift
   struct Manga: Codable, Sendable { }
   ```

6. **Compartir código entre plataformas**
   - ViewModels compartidos entre iOS, macOS, watchOS
   - Network layer compartido
   - Models (DTOs) compartidos
   - KeychainHelper con App Groups

### UI/UX

1. **iOS 17+ features**
   - `ContentUnavailableView` para estados vacíos
   - `#Preview` macro
   - `.task` para inicialización async
   - `@Observable` para state management

2. **Adaptativo iPhone/iPad**
   - Usar `NavigationSplitView` para iPad
   - Layouts responsivos con `ViewThatFits`
   - TabView para iPhone, Sidebar para iPad/Mac

3. **macOS específico**
   - NavigationSplitView (3 columnas)
   - Menús nativos (.commands)
   - Keyboard shortcuts
   - Toolbar personalizado

4. **watchOS específico**
   - UI minimalista
   - Digital Crown navigation
   - Feedback háptico
   - Texto legible en pantalla pequeña

5. **Accesibilidad**
   - Labels descriptivos
   - VoiceOver support
   - Dynamic Type
   - Section headers claros
   - Ver: `accesibilidad.md` para guía completa

### Multi-plataforma

1. **Compartir código**
   - Target Membership en File Inspector
   - ViewModels reutilizables
   - Network layer único
   - DTOs compartidos

2. **App Groups**
   - Configurar para compartir datos
   - Keychain con accessGroup
   - Token compartido entre plataformas

3. **Plataform-specific**
   - Vistas específicas por plataforma
   - Adaptaciones de UI según contexto
   - Aprovechar características únicas

### Testing

1. **Unit tests** para lógica de negocio
2. **Integration tests** para capa de red
3. **UI tests** para flujos críticos
4. **Preview tests** con PreviewData

---

## 🔗 Enlaces Útiles

- [Documentación API](https://mymanga-acacademy-5607149ebe3d.herokuapp.com/docs)
- [Swift Evolution - async/await](https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md)
- [WWDC23 - Observable](https://developer.apple.com/videos/play/wwdc2023/10149/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [macOS HIG](https://developer.apple.com/design/human-interface-guidelines/macos)
- [watchOS HIG](https://developer.apple.com/design/human-interface-guidelines/watchos)

---

## 📝 Notas de Desarrollo

### Decisiones de Arquitectura

1. **¿Por qué NetworkAPI?**
   - Librería creada para el curso
   - Abstrae URLSession
   - Proporciona getJSON() type-safe

2. **¿Por qué @Observable en lugar de @ObservableObject?**
   - API moderna de iOS 17+
   - Mejor performance
   - Menos boilerplate (@Published)
   - Compartible entre plataformas

3. **¿SwiftData o Core Data?**
   - **SwiftData** para iOS (persistencia local)
   - **Solo Cloud** para macOS/watchOS/tvOS/visionOS
   - Sincronización con servidor en todas las plataformas

4. **¿Keychain vs UserDefaults para tokens?**
   - **Siempre Keychain** - seguridad crítica
   - App Groups para compartir entre plataformas
   - AccessGroup configurado

5. **¿Código compartido vs específico?**
   - **ViewModels:** Compartidos (lógica de negocio)
   - **Views:** Específicos por plataforma (UI optimizada)
   - **Models:** Compartidos (DTOs de API)
   - **Network:** Compartido (única fuente de verdad)

### Estado del Proyecto

**Última actualización:** 13 de Diciembre, 2025
**Versión actual:** Deluxe (en progreso)

**Plataformas implementadas:**
- ✅ iOS - Completo
- ✅ macOS - Completo
- ✅ watchOS - Completo
- 📋 tvOS - Planificado
- 📋 visionOS - Planificado

**Características principales:**
- ✅ Autenticación de usuarios
- ✅ Exploración de mangas con filtros
- ✅ Colecciones cloud + local (iOS)
- ✅ Sincronización entre plataformas
- ✅ UI adaptativa por plataforma
- ✅ Búsqueda y paginación

**Próximos pasos:**
1. Implementar tvOS según plan
2. Implementar visionOS según plan
3. Añadir Widgets
4. Implementar Handoff
5. Integrar Shortcuts/Siri

---

**Versión del documento:** 2.0
**Autor:** Claude + Juan Carlos
