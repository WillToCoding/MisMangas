//
//  MisMangas_tvOSApp.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

@main
struct MisMangas_tvOSApp: App {
    @State private var authVM: AuthViewModel
    @State private var cloudVM: CloudCollectionViewModel

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
        }
    }
}
