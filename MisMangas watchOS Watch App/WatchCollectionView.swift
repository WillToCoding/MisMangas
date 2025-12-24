//
//  WatchCollectionView.swift
//  MisMangas watchOS Watch App
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct WatchCollectionView: View {
    @Bindable var cloudVM: CloudCollectionViewModel
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            List {
                ForEach(cloudVM.cloudCollection) { item in
                    NavigationLink(value: item.id) {
                        WatchMangaRow(itemId: item.id, cloudVM: cloudVM)
                    }
                    .id("\(item.id)-\(item.readingVolume ?? 0)")
                }
            }
            .refreshable {
                print("[WatchCollectionView] Pull to refresh")
                await cloudVM.loadCollection()
            }
            .task {
                // Cargar colección cuando aparece la vista
                if !hasAppeared {
                    hasAppeared = true
                    print("[WatchCollectionView] task - Primera carga")
                    await cloudVM.loadCollection()
                }
            }
            .navigationTitle("nav_collection")
            .navigationDestination(for: String.self) { itemId in
                if let item = cloudVM.cloudCollection.first(where: { $0.id == itemId }) {
                    WatchMangaDetailView(item: item) {
                        // Recargar colección al volver
                        print("[WatchCollectionView] Volviendo del detalle - recargando")
                        Task {
                            await cloudVM.loadCollection()
                        }
                    }
                }
            }

            // Overlay para mostrar el loading
            if cloudVM.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
    }
}

#Preview {
    let authVM = AuthViewModel()
    NavigationStack {
        WatchCollectionView(cloudVM: CloudCollectionViewModel(authVM: authVM))
            .environment(authVM)
    }
}
