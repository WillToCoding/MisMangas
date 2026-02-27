# MisMangas

<p align="center">
  <img src="snapshots/App.png" width="120" alt="MisMangas App Icon">
</p>

<h3 align="center">Manga collection manager for all Apple platforms</h3>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-6.0-F05138?style=for-the-badge&logo=swift&logoColor=white" alt="Swift">
  <img src="https://img.shields.io/badge/Platforms-5-007AFF?style=for-the-badge&logo=apple&logoColor=white" alt="Platforms">
  <img src="https://img.shields.io/badge/Clean_Architecture-MVVM-9B59B6?style=for-the-badge" alt="Architecture">
  <img src="https://img.shields.io/badge/License-MIT-2ECC71?style=for-the-badge" alt="License">
</p>

<p align="center">
  <b>🎓 Final project for Swift Developer Program 2026 — Apple Coding Academy</b><br>
  <i>Completed at Deluxe level: 5 platforms + widgets + Siri Shortcuts</i>
</p>

---

<img src="https://img.shields.io/badge/✨_FEATURES-2ECC71?style=for-the-badge" alt="Features">

| | Feature | Description |
|:--:|---------|-------------|
| 📱 | **Multi-platform** | Native UI optimized for each Apple platform |
| 📚 | **64,000+ Mangas** | Browse, search, and filter the complete catalog |
| ☁️ | **Cloud Sync** | Collection syncs across devices with conflict resolution |
| 🧩 | **Widgets** | 3 Home Screen sizes + 3 Lock Screen widgets |
| 🗣️ | **Siri Shortcuts** | Voice commands for quick access |
| 💾 | **Offline Mode** | SwiftData persistence with cover caching |
| 🌍 | **4 Languages** | Spanish, English, Arabic, Japanese |

---

<img src="https://img.shields.io/badge/🚀_ONBOARDING-9B59B6?style=for-the-badge" alt="Onboarding">

<p align="center">
  <img src="snapshots/Onboarding/Next1.png" width="200" alt="Onboarding Step 1">
  &nbsp;&nbsp;&nbsp;
  <img src="snapshots/Onboarding/Next2.png" width="200" alt="Onboarding Step 2">
  &nbsp;&nbsp;&nbsp;
  <img src="snapshots/Onboarding/Next3.png" width="200" alt="Onboarding Step 3">
</p>

---

<img src="https://img.shields.io/badge/📱_iPhone-000000?style=for-the-badge&logo=apple&logoColor=white" alt="iPhone">

<p align="center">
  <img src="snapshots/Targets/iOS/Home.png" width="200" alt="iPhone Home">
  &nbsp;&nbsp;&nbsp;
  <img src="snapshots/Targets/iOS/Profile.png" width="200" alt="iPhone Profile">
</p>

- Tab navigation with adaptive layouts
- Haptic feedback throughout the app
- Siri Shortcuts with App Intents
- Photo picker for profile image
- Pull-to-refresh and infinite scroll
- Swipe actions for quick collection management
- Dynamic Type and VoiceOver support

---

<img src="https://img.shields.io/badge/📱_iPad-000000?style=for-the-badge&logo=apple&logoColor=white" alt="iPad">

<p align="center">
  <img src="snapshots/Targets/iPadOS/MyCollection.png" width="380" alt="iPad Collection">
  &nbsp;&nbsp;
  <img src="snapshots/Targets/iPadOS/RelatedManga.png" width="380" alt="iPad Related Manga">
</p>

- Split view navigation optimized for large screens
- Adaptive grid layouts for all orientations
- Swipe actions for collection management

---

<img src="https://img.shields.io/badge/🖥️_Mac-000000?style=for-the-badge&logo=macos&logoColor=white" alt="Mac">

<p align="center">
  <img src="snapshots/Targets/macOS/Search.png" width="380" alt="Mac Search">
  &nbsp;&nbsp;
  <img src="snapshots/Targets/macOS/CreateAccount.png" width="380" alt="Mac Create Account">
</p>

- 3-column NavigationSplitView
- Keyboard shortcuts: `⌘R` refresh, `⌘,` preferences
- Menu bar commands and toolbar actions
- Resizable window (min 900×600)
- Native macOS settings panel
- Right-click context menus

---

<img src="https://img.shields.io/badge/📺_Apple_TV-000000?style=for-the-badge&logo=appletv&logoColor=white" alt="Apple TV">

<p align="center">
  <img src="snapshots/Targets/tvOS/Photo.png" width="380" alt="Apple TV Photo">
  &nbsp;&nbsp;
  <img src="snapshots/Targets/tvOS/Settings.png" width="380" alt="Apple TV Settings">
</p>

- Focus Engine navigation with Siri Remote
- Hero carousel with top-rated mangas
- Large cards (400×600) optimized for 10-foot UI
- 20 selectable avatars in 5 categories
- Haptic feedback (Siri Remote 2nd gen+)

---

<img src="https://img.shields.io/badge/🥽_Apple_Vision_Pro-000000?style=for-the-badge&logo=apple&logoColor=white" alt="Apple Vision Pro">

<p align="center">
  <img src="snapshots/Targets/visionOS/Links.png" width="350" alt="Apple Vision Pro Links">
</p>

<p align="center">
  <img src="snapshots/Targets/visionOS/Lofin.png" width="350" alt="Apple Vision Pro Login">
  &nbsp;&nbsp;
  <img src="snapshots/Targets/visionOS/DeepL.png" width="350" alt="Apple Vision Pro DeepL">
</p>

- **Immersive 3D Gallery** — Circular layout with up to 12 mangas
- RealityKit rendering with spatial gestures
- Glassmorphic cards with hover effects
- Full collection management with cloud sync
- DeepL translation support

---

<img src="https://img.shields.io/badge/⌚_Apple_Watch-000000?style=for-the-badge&logo=apple&logoColor=white" alt="Apple Watch">

<p align="center">
  <img src="snapshots/Targets/watchOS/Icon.png" width="140" alt="Apple Watch Icon">
  &nbsp;&nbsp;&nbsp;
  <img src="snapshots/Targets/watchOS/List.PNG" width="140" alt="Apple Watch List">
</p>

- Compact collection list with cover thumbnails
- Swipe "+1" for quick volume tracking
- Stats header with reading progress
- Shared session via iPhone Keychain

---

<img src="https://img.shields.io/badge/🧩_WIDGETS-FF2D55?style=for-the-badge" alt="Widgets">

<p align="center">
  <img src="snapshots/Widgets/LockScreen.png" width="240" alt="Lock Screen Widgets">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="snapshots/Widgets/HomeScreen.png" width="240" alt="Home Screen Widgets">
</p>

**Home Screen**
| Size | Mangas | Stats |
|:----:|:------:|:-----:|
| Small | 1 | Total + Progress |
| Medium | 3 | Total + Completed + Reading + Progress |
| Large | 6 | Total + Completed + Reading + Progress |

**Lock Screen**
| Type | Content |
|:----:|:--------|
| Circular | Progress gauge + volume |
| Rectangular | Title + Vol. X/Y + progress bar |
| Inline | "Title - Vol. X/Y" |

---

<img src="https://img.shields.io/badge/🏗️_ARCHITECTURE-9B59B6?style=for-the-badge" alt="Architecture">

Clean Architecture + MVVM. **Zero third-party dependencies** — pure Apple frameworks.

```
┌─────────────────────────────────────────┐
│          Presentation Layer             │
│     Views · ViewModels · Components     │
└───────────────────┬─────────────────────┘
                    │
┌───────────────────▼─────────────────────┐
│            Domain Layer                 │
│       Models · DTOs · Protocols         │
└───────────────────┬─────────────────────┘
                    │
┌───────────────────▼─────────────────────┐
│             Data Layer                  │
│     Network · Storage · SwiftData       │
└─────────────────────────────────────────┘
```

---

<img src="https://img.shields.io/badge/🛠️_TECH_STACK-E67E22?style=for-the-badge" alt="Tech Stack">

| Category | Technologies |
|:--------:|-------------|
| **UI** | SwiftUI, RealityKit, WidgetKit, AppIntents |
| **Data** | SwiftData, Keychain, App Groups |
| **Async** | async/await, @Observable, Sendable, Actors |
| **APIs** | Academy API, Jikan API, DeepL API |
| **Testing** | Swift Testing (100+ tests) |
| **Localization** | String Catalogs (xcstrings) |

---

<img src="https://img.shields.io/badge/📚_FRAMEWORKS-3498DB?style=for-the-badge" alt="Frameworks">

| Platform | Key Frameworks |
|:--------:|----------------|
| **iOS/iPadOS** | WidgetKit, AppIntents, PhotosUI |
| **macOS** | AppKit integration, Settings |
| **tvOS** | TVUIKit, Focus Engine |
| **visionOS** | RealityKit, Spatial Frameworks |
| **watchOS** | WatchKit, ClockKit |
| **Shared** | SwiftUI, SwiftData, Foundation, Security (Keychain) |

---

<img src="https://img.shields.io/badge/📂_PROJECT_STRUCTURE-95A5A6?style=for-the-badge" alt="Structure">

```
MisMangas/
├── 📱 MisMangas/                    # iOS/iPadOS shared code
├── 🖥️ MisMangas macOS/              # macOS target
├── 📺 MisMangas tvOS/               # tvOS target
├── 🥽 MisMangas visionOS/           # visionOS target
├── ⌚ MisMangas watchOS Watch App/  # watchOS target
├── 🧩 MisMangas widget/             # WidgetKit extension
├── 🧪 MisMangasTests/               # Unit tests
└── 📦 Packages/                     # Local packages

Package Dependencies/
└── 🔗 NetworkAPI (local)            # Async/await networking
```

---

<img src="https://img.shields.io/badge/🌐_APIS-E74C3C?style=for-the-badge" alt="APIs">

| API | Purpose | Auth |
|:---:|---------|:----:|
| [**Academy**](https://mymanga-acacademy-5607149ebe3d.herokuapp.com/docs) | Catalog, users, collections | App-Token + JWT |
| [**Jikan**](https://jikan.moe) | Characters, related mangas | None |
| [**DeepL**](https://deepl.com/docs-api) | Synopsis translation | API Key |

---

<img src="https://img.shields.io/badge/🔐_SECURITY-F1C40F?style=for-the-badge" alt="Security">

| What | Where |
|:----:|-------|
| JWT Tokens | iOS Keychain (hardware encrypted) |
| API Keys | `AppConfig.swift` (gitignored) |
| DeepL Key | User-provided, stored in Keychain |
| Sync | iCloud Keychain across devices |

---

<img src="https://img.shields.io/badge/🧪_TESTING-27AE60?style=for-the-badge" alt="Testing">

**Swift Testing** with dependency injection and mocks.

```swift
@Suite("MangaViewModel Tests")
struct MangaVMTests {
    @Test("Fetches mangas successfully")
    func fetchMangas() async {
        let vm = MangaViewModel(repository: NetworkTest())
        await vm.fetchMangas()
        #expect(vm.mangas.count > 0)
    }
}
```

| Mock | Purpose |
|:----:|---------|
| `NetworkTest` | Returns test data |
| `NetworkTestWithError` | Simulates network errors |

---

<img src="https://img.shields.io/badge/🌍_LOCALIZATION-1ABC9C?style=for-the-badge" alt="Localization">

| Language | Code | Coverage |
|:--------:|:----:|:--------:|
| 🇪🇸 Spanish | `ES` | 100% |
| 🇺🇸 English | `EN` | 98.5% |
| 🇸🇦 Arabic | `AR` | 98.5% |
| 🇯🇵 Japanese | `JA` | 98.5% |

**452 localized strings** using String Catalogs (xcstrings)

---

<img src="https://img.shields.io/badge/♿_ACCESSIBILITY-2980B9?style=for-the-badge" alt="Accessibility">

- **150 accessibility labels** across all platforms
- VoiceOver optimized with semantic headers (H1, H2, H3)
- Dynamic Type support
- Reduce Motion / Reduce Transparency respected
- High contrast mode compatible

---

<img src="https://img.shields.io/badge/📋_REQUIREMENTS-7F8C8D?style=for-the-badge" alt="Requirements">

| Platform | Version |
|:--------:|:-------:|
| iOS / iPadOS | 26.2+ |
| macOS | 26.2+ |
| tvOS | 26.2+ |
| watchOS | 26.2+ |
| visionOS | 26.2+ |
| Xcode | 26.2+ |

---

<img src="https://img.shields.io/badge/🚀_INSTALLATION-2ECC71?style=for-the-badge" alt="Installation">

```bash
git clone https://github.com/WillToCoding/MisMangas.git
cd MisMangas
cp MisMangas/AppConfig.example.swift MisMangas/AppConfig.swift
```

Edit `AppConfig.swift` with your tokens:

```swift
enum AppConfig {
    static let academyToken = "YOUR_ACADEMY_TOKEN"
    static let deepLToken = "YOUR_DEEPL_TOKEN"  // Optional
}
```

```bash
open MisMangas.xcodeproj
```

---

<img src="https://img.shields.io/badge/📦_DEPENDENCIES-34495E?style=for-the-badge" alt="Dependencies">

| Package | Purpose |
|:-------:|---------|
| [**NetworkAPI**](https://github.com/WillToCoding/NetworkAPI) | Async/await networking layer |

---

<p align="center">
  <b>MIT License</b> · Made with ❤️ by <b>Juan Carlos</b>
</p>

<p align="center">
  <i>Swift Developer Program 2026 — Apple Coding Academy</i>
</p>
