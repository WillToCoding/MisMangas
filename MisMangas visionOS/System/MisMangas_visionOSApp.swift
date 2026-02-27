//
//  MisMangas_visionOSApp.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI
import SwiftData

@main
struct MisMangas_visionOSApp: App {
    @State private var authVM: AuthViewModel
    @State private var cloudVM: CloudCollectionViewModel
    @State private var translationService = TranslationService()

    init() {
        let auth = AuthViewModel()
        _authVM = State(initialValue: auth)
        _cloudVM = State(initialValue: CloudCollectionViewModel(authVM: auth))
    }

    var body: some Scene {
        // Ventana principal
        WindowGroup {
            VisionRootView()
                .environment(authVM)
                .environment(cloudVM)
                .environment(translationService)
        }
        .defaultSize(width: 1200, height: 800)
        .modelContainer(.production)

        // Espacio inmersivo opcional
        ImmersiveSpace(id: "ImmersiveMangaSpace") {
            VisionImmersiveView()
                .environment(cloudVM)
        }
    }
}
