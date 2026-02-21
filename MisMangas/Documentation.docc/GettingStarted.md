# Primeros Pasos con MisMangas

Aprende a configurar y usar la arquitectura de MisMangas en tu proyecto.

## Overview

MisMangas utiliza una arquitectura **MVVM** con inyeccion de dependencias que facilita el testing y la separacion de responsabilidades.

### Estructura de ViewModels

Los ViewModels utilizan el macro `@Observable` de Swift 5.9 para la reactividad:

```swift
@MainActor
@Observable
final class MangaViewModel {
    var mangas: [Manga] = []
    var isLoading = false
    var errorMessage: String?

    let repository: NetworkRepository

    init(repository: NetworkRepository = Network()) {
        self.repository = repository
    }
}
```

### Inyeccion de Dependencias

Todos los ViewModels aceptan un `NetworkRepository` en su inicializador, permitiendo inyectar mocks para testing:

```swift
// Produccion
let viewModel = MangaViewModel()

// Testing
let mockRepository = MockNetworkRepository()
let viewModel = MangaViewModel(repository: mockRepository)
```

### Capa de Red

La capa de red sigue el patron **Repository** con una fachada que unifica multiples APIs:

```swift
// El protocolo define las operaciones disponibles
protocol NetworkRepository: Sendable {
    func getMangas(page: Int, per: Int) async throws -> PaginatedResponse<Manga>
    func searchMangasContains(_ text: String, page: Int, per: Int) async throws -> PaginatedResponse<Manga>
    // ...
}

// La implementacion concreta unifica Academy y Jikan APIs
struct Network: NetworkRepository {
    private let academy = AcademyRepository()
    private let jikan = JikanRepository()
    // ...
}
```

### Autenticacion

El flujo de autenticacion utiliza Keychain para almacenar el token de forma segura:

```swift
// Login
try await authVM.login(email: "user@email.com", password: "password")

// El token se guarda automaticamente en Keychain
// y se renueva cada 2 dias

// Verificar autenticacion
if authVM.isAuthenticated {
    // Usuario logueado
}
```

### Coleccion en la Nube

La coleccion del usuario se sincroniza con la API:

```swift
// Cargar coleccion
await cloudVM.loadCollection()

// Agregar manga
try await cloudVM.addToCollection(
    manga: manga,
    volumesOwned: [1, 2, 3],
    readingVolume: 2,
    completeCollection: false
)

// Verificar si un manga esta en la coleccion
let isInCollection = cloudVM.isInCollection(manga.id)
```

## Topics

### ViewModels Principales

- ``MangaViewModel``
- ``AuthViewModel``
- ``CloudCollectionViewModel``
