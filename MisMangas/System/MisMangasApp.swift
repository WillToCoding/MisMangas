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
    @State private var authVM = AuthViewModel()
    @State private var cloudCollectionVM: CloudCollectionViewModel?

    init() {
        // Inicializar cloudCollectionVM después de authVM
        let auth = AuthViewModel()
        _authVM = State(initialValue: auth)
        _cloudCollectionVM = State(initialValue: CloudCollectionViewModel(authVM: auth))
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(authVM)
                .environment(cloudCollectionVM!)
        }
        .modelContainer(.production)
    }
}
