# ``MisMangas``

Aplicación multiplataforma para gestionar tu colección de mangas.

@Metadata {
    @PageColor(purple)
}

## Overview

**MisMangas** consume una API REST con más de 64.000 mangas. Soporta iOS, iPadOS, macOS, tvOS, visionOS y watchOS.

## Topics

### ViewModels

- ``AuthViewModel``
- ``HomeViewModel``
- ``MangaViewModel``
- ``FilterViewModel``
- ``CloudCollectionViewModel``
- ``SyncViewModel``
- ``MangaDetailViewModel``
- ``MangaCoverVM``

### Modelos (API)

- ``Manga``
- ``Author``
- ``Genre``
- ``Theme``
- ``Demographic``
- ``UserMangaCollection``
- ``PaginatedResponse``

### Persistencia (SwiftData)

- ``MangaModel``
- ``UserCollection``
- ``OwnedVolume``
- ``DataContainer``

### Protocolos

- ``CollectionItem``
- ``NetworkRepository``
- ``KeychainServiceProtocol``

### Estado

- ``ViewState``
- ``ReadingStatus``
