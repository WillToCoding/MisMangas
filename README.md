# MisMangas

<p align="center">
  <img src="snapshots/App.png" width="128" alt="MisMangas App Icon">
</p>

<p align="center">
  <strong>Manga collection manager for all Apple platforms</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white" alt="Swift">
  <img src="https://img.shields.io/badge/Platforms-iOS%20%7C%20iPadOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20visionOS-007AFF" alt="Platforms">
  <img src="https://img.shields.io/badge/Architecture-Clean%20MVVM-purple" alt="Architecture">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

<p align="center">
  <img src="snapshots/Targets.png" width="600" alt="All Platforms">
</p>

> Final project for **Swift Developer Program 2025** (Apple Coding Academy).
> Completed at **Deluxe level**: 6 platforms + widgets + Siri Shortcuts.

---

## Features

| Feature | Description |
|---------|-------------|
| **Multi-platform** | Native UI for iOS, iPadOS, macOS, watchOS, tvOS, visionOS |
| **64,000+ Mangas** | Browse, search, and filter the complete catalog |
| **Cloud Sync** | Collection syncs across devices with conflict resolution |
| **Widgets** | 3 Home Screen sizes + 3 Lock Screen widgets |
| **Siri Shortcuts** | Voice commands for quick access |
| **Offline Mode** | SwiftData persistence with cover caching |
| **4 Languages** | Spanish, English, Arabic, Japanese |

---

## Screenshots

<!-- TODO: Add platform screenshots -->

| iOS | macOS | visionOS |
|:---:|:-----:|:--------:|
| ![iOS](snapshots/ios.png) | ![macOS](snapshots/macos.png) | ![visionOS](snapshots/visionos.png) |

| tvOS | watchOS | Widgets |
|:----:|:-------:|:-------:|
| ![tvOS](snapshots/tvos.png) | ![watchOS](snapshots/watchos.png) | ![Widgets](snapshots/widgets.png) |

---

## Architecture

Clean Architecture with MVVM. **No third-party dependencies** — pure Apple frameworks.

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│    Views · ViewModels · Components  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│           Domain Layer              │
│       Models · DTOs · Protocols     │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│            Data Layer               │
│    Network · Storage · SwiftData    │
└─────────────────────────────────────┘
```

---

## Tech Stack

| Category | Technologies |
|----------|-------------|
| **UI** | SwiftUI, RealityKit (visionOS) |
| **Persistence** | SwiftData, Keychain, App Groups |
| **Concurrency** | async/await, @Observable, Sendable, Actors |
| **APIs** | Academy API, Jikan API, DeepL API |
| **Testing** | Swift Testing (100+ tests) |
| **Localization** | String Catalogs (xcstrings) |

---

## Project Structure

```
MisMangas/
├── MisMangas/                 # iOS/iPadOS
│   ├── Views/                 # SwiftUI views
│   ├── ViewModel/             # @Observable ViewModels
│   ├── Model/                 # DTOs (Academy, Jikan)
│   ├── DataModel/             # SwiftData models
│   ├── Network/               # Repositories
│   └── Intents/               # Siri Shortcuts
├── MisMangas macOS/           # macOS (NavigationSplitView)
├── MisMangas tvOS/            # tvOS (Focus Engine)
├── MisMangas visionOS/        # visionOS (RealityKit)
├── MisMangas watchOS/         # watchOS
├── MisMangas widget/          # WidgetKit
├── Packages/NetworkAPI/       # Local Swift Package
└── MisMangasTests/            # Swift Testing
```

---

## Key Implementations

### Platform-Specific UI

- **iOS/iPadOS** — Adaptive layouts with `@Environment(\.horizontalSizeClass)`
- **macOS** — 3-column `NavigationSplitView` with keyboard shortcuts
- **tvOS** — Focus Engine with hero carousel
- **visionOS** — Immersive 3D gallery using RealityKit
- **watchOS** — Compact views with swipe gestures

### Cloud Sync with Conflict Resolution

```swift
@ModelActor
actor DataContainer {
    func syncCollections(_ remote: [UserMangaCollection]) async throws
    func resolveConflict(_ item: MangaModel, strategy: ConflictStrategy)
}
```

### Secure Token Storage

```swift
final class KeychainHelper: KeychainServiceProtocol {
    func save(_ token: String, for key: String) throws
    func retrieve(for key: String) throws -> String?
}
```

---

## Requirements

| Platform | Version |
|----------|---------|
| iOS/iPadOS | 26.2+ |
| macOS | 26.2+ |
| tvOS | 26.2+ |
| watchOS | 26.2+ |
| visionOS | 26.2+ |
| Xcode | 26+ |

---

## Installation

```bash
git clone https://github.com/WillToCoding/MisMangas.git
cd MisMangas
cp MisMangas/AppConfig.example.swift MisMangas/AppConfig.swift
# Add your token in AppConfig.swift
open MisMangas.xcodeproj
```

---

## Dependencies

- [NetworkAPI](https://github.com/WillToCoding/NetworkAPI) — Networking async/await

---

## APIs

| API | Purpose | Auth |
|-----|---------|------|
| [Academy](https://mymanga-acacademy-5607149ebe3d.herokuapp.com/docs) | Catalog, users, collections | App-Token + JWT |
| [Jikan](https://jikan.moe) | Characters, related mangas | None |
| [DeepL](https://deepl.com/docs-api) | Synopsis translation | API Key |

---

## Testing

```bash
xcodebuild test -scheme MisMangas \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

## Author

**Juan Carlos** — Swift Developer Program 2025
