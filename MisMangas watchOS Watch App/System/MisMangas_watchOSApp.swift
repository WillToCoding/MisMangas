//
//  MisMangas_watchOSApp.swift
//  MisMangas watchOS Watch App
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

@main
struct MisMangas_watchOS_Watch_AppApp: App {
    @State private var authVM: AuthViewModel
    @State private var cloudVM: CloudCollectionViewModel

    init() {
        print("[watchOS APP] === INICIANDO APP ===")
        let auth = AuthViewModel()
        print("[watchOS APP] AuthViewModel creado")
        print("[watchOS APP]   - isAuthenticated: \(auth.isAuthenticated)")
        print("[watchOS APP]   - authToken existe: \(auth.authToken != nil)")
        print("[watchOS APP]   - userEmail: \(auth.userEmail ?? "nil")")

        _authVM = State(initialValue: auth)
        _cloudVM = State(initialValue: CloudCollectionViewModel(authVM: auth))

        print("[watchOS APP] === ViewModels configurados ===")
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(authVM)
                .environment(cloudVM)
        }
    }
}
