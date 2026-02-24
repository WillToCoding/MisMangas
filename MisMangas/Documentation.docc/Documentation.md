# ``MisMangas``

Aplicacion multiplataforma para gestionar tu coleccion de mangas con sincronizacion en la nube.

@Metadata {
    @PageColor(purple)
}

## Overview

**MisMangas** es una aplicacion nativa de Apple desarrollada en SwiftUI que permite a los usuarios explorar, buscar y gestionar su coleccion personal de mangas. La app consume una API REST con mas de 64.000 mangas publicados.

### Plataformas soportadas

| Plataforma | Estado |
|------------|--------|
| iOS / iPadOS | Completo |
| macOS | Completo |
| watchOS | Completo |
| tvOS | Funcional |
| visionOS | Funcional |

### Caracteristicas principales

- **Exploracion de mangas**: Navega por el catalogo completo con paginacion infinita
- **Busqueda avanzada**: Filtra por genero, demografia, tema, puntuacion y año
- **Coleccion en la nube**: Sincroniza tu coleccion entre dispositivos via API REST
- **Modo offline**: Accede a tu coleccion sin conexion gracias a SwiftData
- **Widgets**: Home Screen y Lock Screen widgets
- **Siri Shortcuts**: Acceso rapido mediante App Intents
- **Multi-idioma**: ES, EN, AR, JA
- **Accesibilidad**: Soporte para VoiceOver y Dynamic Type

### Arquitectura

La aplicacion sigue **Clean Architecture** con el patron **MVVM**:

```
Presentation  →  Views, ViewModels, Components
Domain        →  Models (Academy, Jikan)
Data          →  Network, Storage, DataModel
```

### APIs

| API | Uso |
|-----|-----|
| Academy | Catalogo, autenticacion, colecciones |
| Jikan | Personajes, relaciones, filtros avanzados |
| DeepL | Traduccion de sinopsis |

## Topics

### Essentials

- <doc:GettingStarted>

### ViewModels

- ``MangaViewModel``
- ``AuthViewModel``
- ``FilterViewModel``
- ``CloudCollectionViewModel``
- ``HomeViewModel``

### DTOs (Academy API)

- ``Manga``
- ``Author``
- ``Genre``
- ``Theme``
- ``Demographic``
- ``UserMangaCollection``
- ``PaginatedResponse``
- ``CustomSearch``

### Persistencia (SwiftData)

- ``MangaModel``
- ``UserCollection``

### Autenticacion

- ``AuthError``
- ``KeychainHelper``
