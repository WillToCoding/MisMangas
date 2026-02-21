# MisMangas

<p align="center">
  <img src="snapshots/App.png" width="128" alt="MisMangas App Icon">
</p>

<p align="center">
  Gestiona tu colección de manga en todas las plataformas Apple.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white" alt="Swift">
  <img src="https://img.shields.io/badge/Platforms-iOS%20%7C%20iPadOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20visionOS-007AFF" alt="Platforms">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

<p align="center">
  <img src="snapshots/Targets.png" width="600" alt="All Platforms">
</p>

## Características

- Explora +64,000 mangas con filtros avanzados
- Guarda tu colección y registra progreso de lectura
- Sincronización en la nube entre dispositivos
- Widgets para Home Screen y Lock Screen
- Siri Shortcuts
- Soporte para ES, EN, AR, JA

## Requisitos

- iOS/iPadOS 26.1+
- macOS 26.1+
- watchOS 26.1+
- tvOS 26.1+
- visionOS 26.1+
- Xcode 26+

## Instalación

```bash
git clone https://github.com/WillToCoding/MisMangas.git
cd MisMangas
cp MisMangas/AppConfig.example.swift MisMangas/AppConfig.swift
# Añade tu token en AppConfig.swift
open MisMangas.xcodeproj
```

## Dependencias

- [NetworkAPI](https://github.com/WillToCoding/NetworkAPI) - Networking async/await

## Arquitectura

SwiftUI + SwiftData + Clean Architecture (MVVM)

```
Presentation  →  Views, ViewModels, Components
Domain        →  Models (Academy, Jikan)
Data          →  Network, Storage, DataModel
```

## APIs

| API | Uso |
|-----|-----|
| Academy | Catálogo, autenticación, colecciones |
| [Jikan](https://jikan.moe) | Personajes, relaciones |
| [DeepL](https://deepl.com) | Traducción de sinopsis |

## Licencia

MIT
