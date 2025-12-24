# Análisis de Ideas Futuras - MisMangas

Análisis de viabilidad técnica para nuevas funcionalidades.

---

## 1. Sistema de filtros: búsqueda por años + demografía + puntuación

### Viabilidad: PARCIAL

**Estado actual del API (CustomSearch):**
```swift
struct CustomSearch: Codable {
    var searchTitle: String?
    var searchAuthorFirstName: String?
    var searchAuthorLastName: String?
    var searchGenres: [String]?
    var searchThemes: [String]?
    var searchDemographics: [String]?  // ✅ YA EXISTE
    var searchContains: Bool
}
```

| Filtro | API Soporta | Alternativa |
|--------|-------------|-------------|
| Demografía | ✅ Sí | Ya implementado |
| Año | ❌ No | Filtrado client-side (lento) |
| Puntuación | ❌ No | Filtrado client-side (lento) |

**Conclusión:** Demografía funciona. Año y puntuación requerirían cargar todos los mangas y filtrar en el cliente, lo cual no es eficiente con 64,000+ mangas.

**Posible solución:** Usar Jikan API que sí soporta estos filtros:
```
/manga?min_score=8&start_date=2020-01-01&end_date=2023-12-31
```

---

## 2. Disponibilidad en Kindle, Apple Books, Wallapop, etc.

### Viabilidad: MUY DIFÍCIL / IMPOSIBLE

| Plataforma | API Pública | Notas |
|------------|-------------|-------|
| Amazon/Kindle | ❌ No | Product Advertising API requiere ser afiliado y no permite búsquedas por ISBN de manga |
| Apple Books | ❌ No | No existe API pública para búsqueda de catálogo |
| Wallapop | ⚠️ Limitada | API no oficial, solo productos de segunda mano |
| Google Books | ✅ Sí | Tiene API pero catálogo de manga muy limitado |
| BookDepository | ❌ Cerrado | Ya no existe |

**Alternativa realista:**
- Generar enlaces de búsqueda directos (no verificar disponibilidad):
  ```
  https://www.amazon.es/s?k=Dragon+Ball+manga
  https://es.wallapop.com/search?keywords=Dragon+Ball+manga
  ```
- El usuario hace clic y ve resultados en la web

**Conclusión:** No es posible verificar disponibilidad real. Solo se pueden generar enlaces de búsqueda.

---

## 3. Manejar idioma coherente en la interfaz (Localización)

### Viabilidad: TOTALMENTE POSIBLE ✅

SwiftUI soporta localización nativa mediante:

1. Crear `Localizable.strings` para cada idioma
2. Usar `LocalizedStringKey` en textos
3. Detectar idioma del dispositivo automáticamente

**Implementación:**
```
MisMangas/
├── es.lproj/
│   └── Localizable.strings
├── en.lproj/
│   └── Localizable.strings
└── ja.lproj/  (opcional japonés)
    └── Localizable.strings
```

**Ejemplo:**
```swift
// Antes
Text("Mi Colección")

// Después
Text("collection_title")  // Se traduce automáticamente
```

**Esfuerzo estimado:** Medio (revisar todos los textos hardcodeados)

---

## 4. Manejar fondo (personalización visual)

### Viabilidad: TOTALMENTE POSIBLE ✅

**Opciones:**

| Tipo | Dificultad | Implementación |
|------|------------|----------------|
| Colores predefinidos | Fácil | `@AppStorage` + array de colores |
| Imagen de fondo | Media | Selector de fotos + guardado en FileManager |
| Gradientes | Fácil | Presets de gradientes |
| Temas (claro/oscuro/custom) | Media | Ya tienes parte implementada |

**Ya implementado:**
- Modo claro/oscuro en Preferencias macOS

**Por implementar:**
- Selector de color de acento
- Fondos personalizados por vista

---

## 5. Almas Gemelas (matching de usuarios por puntuaciones)

### Viabilidad: REQUIERE BACKEND CUSTOM ⚠️

**Requisitos:**
1. Sistema de puntuación individual por manga (el usuario puntúa)
2. Base de datos que almacene puntuaciones de todos los usuarios
3. Algoritmo de matching (similitud de coseno, etc.)
4. API para consultar usuarios similares

**El API actual NO soporta:**
- Puntuaciones personalizadas por usuario
- Consulta de otros usuarios
- Sistema social

**Solución posible:**
- Crear backend propio (Firebase, Supabase, Vapor)
- O usar puntuación de MAL del manga (no personalizada)

**Conclusión:** No viable con la infraestructura actual. Requeriría desarrollo backend significativo.

---

## 6. Terminar Siri en Inglés

### Viabilidad: TOTALMENTE POSIBLE ✅

**Estado actual:** Shortcuts solo en español

**Implementación:**
```swift
struct MisMangasShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowCurrentReadingIntent(),
            phrases: [
                // Español
                "¿Qué manga estoy leyendo en \(.applicationName)?",
                "Mi manga actual en \(.applicationName)",
                // Inglés
                "What manga am I reading in \(.applicationName)?",
                "My current manga in \(.applicationName)",
                "Show my reading progress in \(.applicationName)"
            ],
            shortTitle: "Current Manga",
            systemImageName: "book.fill"
        )
        // ... más shortcuts
    }
}
```

**Esfuerzo:** Bajo - solo añadir frases en inglés

---

## 7. Enlace a YouTube con videos del Manga/Anime

### Viabilidad: TOTALMENTE POSIBLE ✅

**Opción A - Enlaces directos (recomendada):**
```swift
func youtubeSearchURL(for manga: Manga) -> URL? {
    let query = "\(manga.title) manga trailer PV".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    return URL(string: "https://www.youtube.com/results?search_query=\(query ?? "")")
}
```

**Opción B - YouTube Data API:**
- Requiere API Key de Google
- Permite mostrar thumbnails y títulos en la app
- Límite de 10,000 requests/día gratis

**Implementación sugerida:**
- Añadir botón "Ver en YouTube" en MangaDetailView
- Abre Safari/YouTube app con la búsqueda

---

## 8. Login echa del dispositivo anterior

### Viabilidad: DEPENDE DEL BACKEND ⚠️

**Comportamiento actual:**
El API de la academia probablemente invalida tokens anteriores al generar uno nuevo.

**Posibles causas:**
1. Token único por usuario (cada login genera nuevo token e invalida anterior)
2. Expiración de tokens corta
3. Diseño de seguridad del backend

**¿Se puede cambiar desde la app?** NO

**Soluciones posibles:**
1. Guardar sesión más persistentemente (ya lo haces con Keychain)
2. Implementar renovación automática de token (ya tienes `renewToken`)
3. Contactar al proveedor del API para entender el comportamiento

**Conclusión:** Es comportamiento del servidor, no controlable desde el cliente.

---

## 9. Mangas relacionados (como personajes)

### Viabilidad: TOTALMENTE POSIBLE ✅

**Jikan API soporta:**

```
GET /manga/{id}/relations
```

**Respuesta ejemplo:**
```json
{
  "data": [
    {
      "relation": "Sequel",
      "entry": [
        { "mal_id": 43, "name": "Dragon Ball Z", "type": "manga" }
      ]
    },
    {
      "relation": "Side story",
      "entry": [
        { "mal_id": 44, "name": "Dragon Ball SD", "type": "manga" }
      ]
    }
  ]
}
```

**Tipos de relaciones:**
- Sequel / Prequel
- Side story
- Spin-off
- Alternative version
- Adaptation (anime)

**También disponible:**
```
GET /manga/{id}/recommendations
```
Devuelve mangas similares recomendados por usuarios de MAL.

**Implementación:** Igual que personajes - sección horizontal scrollable.

---

## 10. Info del Anime conectado

### Viabilidad: TOTALMENTE POSIBLE ✅

**Jikan API es también API de Anime:**

```
GET /anime/{id}                    // Info de un anime
GET /anime?q=dragon+ball           // Buscar anime
GET /manga/{id}/relations          // Incluye adaptaciones anime
```

**Datos disponibles del anime:**
- Título, sinopsis, puntuación
- Episodios, duración
- Estudios de animación
- Fecha de emisión
- Trailer de YouTube (¡incluido!)
- Personajes con voces

**Implementación sugerida:**
1. En MangaDetailView, si existe adaptación anime, mostrar sección "Anime"
2. Al pulsar, cargar datos del anime desde Jikan
3. Mostrar: poster, puntuación, episodios, enlace a trailer

**Ejemplo de flujo:**
```
Manga: Dragon Ball (id: 42)
    ↓ GET /manga/42/relations
Encuentra: Adaptation → Anime Dragon Ball (id: 223)
    ↓ GET /anime/223
Muestra: Info del anime con trailer
```

---

## Resumen Ejecutivo

| # | Idea | Viabilidad | Esfuerzo |
|---|------|------------|----------|
| 1 | Filtros avanzados | ⚠️ Parcial (usar Jikan) | Medio |
| 2 | Disponibilidad tiendas | ❌ Solo enlaces | Bajo |
| 3 | Localización idiomas | ✅ Posible | Medio |
| 4 | Fondos personalizados | ✅ Posible | Bajo |
| 5 | Almas gemelas | ❌ Requiere backend | Alto |
| 6 | Siri en inglés | ✅ Posible | Bajo |
| 7 | YouTube videos | ✅ Posible | Bajo |
| 8 | Login multi-dispositivo | ⚠️ Backend decide | N/A |
| 9 | Mangas relacionados | ✅ Posible | Bajo |
| 10 | Info Anime | ✅ Posible | Medio |

---

## Recomendación de prioridad

**Quick wins (implementar primero):**
1. #7 - YouTube (5 minutos)
2. #9 - Mangas relacionados (30 min, ya tienes el patrón)
3. #6 - Siri inglés (10 minutos)

**Medio plazo:**
4. #10 - Info Anime (1-2 horas)
5. #3 - Localización (2-3 horas)
6. #4 - Fondos (1 hora)

**Requiere más análisis:**
7. #1 - Filtros (evaluar migrar a Jikan)
8. #2 - Enlaces tiendas (solo como enlaces, no disponibilidad real)

**No viable actualmente:**
9. #5 - Almas gemelas
10. #8 - Control de sesiones
