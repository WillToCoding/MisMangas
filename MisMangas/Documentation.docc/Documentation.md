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
| tvOS | En desarrollo |
| visionOS | En desarrollo |

### Caracteristicas principales

- **Exploracion de mangas**: Navega por el catalogo completo con paginacion infinita
- **Busqueda avanzada**: Filtra por genero, demografia, tema, puntuacion y anio
- **Coleccion en la nube**: Sincroniza tu coleccion entre dispositivos via API REST
- **Modo offline**: Accede a tu coleccion sin conexion gracias a SwiftData
- **Widgets**: Visualiza tu progreso de lectura desde la pantalla de inicio
- **Accesibilidad**: Soporte completo para VoiceOver y Dynamic Type

### Arquitectura

La aplicacion sigue el patron **MVVM** (Model-View-ViewModel) con inyeccion de dependencias:

```
MisMangas/
├── Model/           # Modelos de datos (Codable)
├── ViewModel/       # Logica de negocio (@Observable)
├── Views/           # Vistas SwiftUI
├── Network/         # Capa de red (Repository pattern)
├── DataModel/       # SwiftData para persistencia
└── Storage/         # Keychain y almacenamiento local
```

### API REST

La app consume dos APIs:
- **Academy API**: API principal con datos de mangas, autenticacion y colecciones
- **Jikan API**: API secundaria para personajes, relaciones y filtros avanzados

## Topics

### Essentials

- <doc:GettingStarted>

### ViewModels

- ``MangaViewModel``
- ``AuthViewModel``
- ``FilterViewModel``
- ``CloudCollectionViewModel``

### Capa de Red

- ``NetworkRepository``
- ``Network``

### Modelos de Datos

- ``Manga``
- ``Author``
- ``UserMangaCollection``
- ``PaginatedResponse``

### Autenticacion

- ``AuthError``
- ``KeychainHelper``

### Filtros y Busqueda

- ``MangaFilters``
- ``SortOption``
- ``CustomSearch``

### Almacenamiento Local

- ``MangaModel``
- ``UserCollection``
