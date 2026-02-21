//
//  VisionCollectionView.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct VisionCollectionView: View {
    @Bindable var cloudVM: CloudCollectionViewModel
    @Environment(\.scenePhase) private var scenePhase

    // Grid 3x3 para aprovechar espacio visionOS
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 40)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 40) {
                ForEach(cloudVM.cloudCollection) { item in
                    NavigationLink(value: item.id) {
                        VisionMangaCard(item: item)
                    }
                    .buttonStyle(.plain)
                    .id("\(item.id)-\(item.readingVolume ?? 0)")
                }
            }
            .padding(60)
        }
        .navigationTitle("nav_collection")
        .navigationDestination(for: String.self) { itemId in
            if let item = cloudVM.cloudCollection.first(where: { $0.id == itemId }) {
                VisionMangaDetailView(item: item) {
                    // Callback cuando se guarda
                    print("[COLLECTION] Callback onSave ejecutado - Colección tiene \(cloudVM.cloudCollection.count) items")
                    if let updated = cloudVM.cloudCollection.first(where: { $0.id == itemId }) {
                        print("[COLLECTION] Item actualizado - Vol: \(updated.readingVolume ?? 0)")
                    }
                }
            }
        }
        .refreshable {
            await cloudVM.loadCollection()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                Task {
                    await cloudVM.loadCollection()
                }
            }
        }
        .ornament(attachmentAnchor: .scene(.top)) {
            if cloudVM.isLoading {
                ProgressView()
                    .padding()
                    .glassBackgroundEffect()
            }
        }
    }
}
