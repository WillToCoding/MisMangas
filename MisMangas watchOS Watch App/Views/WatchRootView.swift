//
//  WatchRootView.swift
//  MisMangas watchOS Watch App
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct WatchRootView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                if !authVM.isAuthenticated {
                    WatchLoginPromptView()
                } else if cloudVM.state.isLoading && cloudVM.cloudCollection.isEmpty {
                    ProgressView("loading_collection")
                } else if cloudVM.cloudCollection.isEmpty {
                    ContentUnavailableView(
                        "collection_empty_title",
                        systemImage: "book",
                        description: Text("collection_empty_description")
                    )
                } else {
                    WatchCollectionView(cloudVM: cloudVM)
                }
            }
            .task {
                if authVM.isAuthenticated {
                    print("[WatchRootView] task - Cargando colección inicial")
                    await cloudVM.loadCollection()
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active && authVM.isAuthenticated {
                    print("[WatchRootView] App activa - recargando colección")
                    Task {
                        await cloudVM.loadCollection()
                    }
                }
            }
        }
    }
}

// MARK: - Login Prompt
struct WatchLoginPromptView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "applewatch.and.iphone")
                .font(.largeTitle)
                .foregroundStyle(.blue)

            Text("action_login")
                .font(.headline)

            Text("watch_login_prompt")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    WatchRootView()
        .environment(AuthViewModel())
        .environment(CloudCollectionViewModel(authVM: AuthViewModel()))
}
