//
//  MisMangas_tvOSApp.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI
import SwiftData

@main
struct MisMangas_tvOSApp: App {
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
            TVRootView()
                .environment(authVM)
                .environment(cloudVM)
                .environment(translationService)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active && authVM.isAuthenticated {
                        // Recargar colección al volver a primer plano
                        Task {
                            await cloudVM.loadCollection()
                        }
                    }
                }
        }
        .modelContainer(.production)
    }
}
