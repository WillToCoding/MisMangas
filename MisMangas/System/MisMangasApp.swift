//
//  MisMangasApp.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import SwiftUI
import SwiftData

@main
struct MisMangasApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var authVM = AuthViewModel()
    @State private var cloudCollectionVM: CloudCollectionViewModel?
    @State private var translationService = TranslationService()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Inicializar cloudCollectionVM después de authVM
        let auth = AuthViewModel()
        _authVM = State(initialValue: auth)
        _cloudCollectionVM = State(initialValue: CloudCollectionViewModel(authVM: auth))
    }

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                MainTabView()
                    .environment(authVM)
                    .environment(cloudCollectionVM!)
                    .environment(translationService)
            } else {
                OnboardingView()
            }
        }
        .modelContainer(.production)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && authVM.isAuthenticated {
                // Recargar colección al volver a primer plano
                Task {
                    await cloudCollectionVM?.loadCollection()
                }
            }
        }
    }
}
