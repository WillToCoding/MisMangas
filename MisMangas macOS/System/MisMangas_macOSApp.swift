//
//  MisMangas_macOSApp.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI
import SwiftData

@main
struct MisMangas_macOSApp: App {
    @State private var authVM: AuthViewModel
    @State private var cloudVM: CloudCollectionViewModel
    @State private var translationService = TranslationService()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let auth = AuthViewModel()
        _authVM = State(initialValue: auth)
        _cloudVM = State(initialValue: CloudCollectionViewModel(authVM: auth))
    }

    var body: some Scene {
        WindowGroup {
            MacMainView()
                .environment(authVM)
                .environment(cloudVM)
                .environment(translationService)
                .frame(minWidth: 900, minHeight: 600)
        }
        .modelContainer(.production)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && authVM.isAuthenticated {
                // Recargar colección al volver a primer plano
                Task {
                    await cloudVM.loadCollection()
                }
            }
        }
        .commands {
            MacCommands()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)

        // Ventana de Preferencias
        Settings {
            MacPreferencesView()
                .environment(authVM)
                .environment(cloudVM)
                .environment(translationService)
        }
        .modelContainer(.production)
    }
}

// MARK: - Menu Commands
struct MacCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("menu_search_manga") {
                NotificationCenter.default.post(name: .focusSearchField, object: nil)
            }
            .keyboardShortcut("f", modifiers: .command)

            Divider()

            Button("menu_refresh") {
                NotificationCenter.default.post(name: .refreshContent, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)
        }

        CommandGroup(after: .sidebar) {
            Button("nav_home") {
                NotificationCenter.default.post(name: .navigateToSection, object: NavigationItem.home)
            }
            .keyboardShortcut("1", modifiers: .command)

            Button("nav_collection") {
                NotificationCenter.default.post(name: .navigateToSection, object: NavigationItem.collection)
            }
            .keyboardShortcut("2", modifiers: .command)

            Button("nav_profile") {
                NotificationCenter.default.post(name: .navigateToSection, object: NavigationItem.profile)
            }
            .keyboardShortcut("3", modifiers: .command)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let focusSearchField = Notification.Name("focusSearchField")
    static let refreshContent = Notification.Name("refreshContent")
    static let navigateToSection = Notification.Name("navigateToSection")
}
