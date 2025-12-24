//
//  TVCollectionView.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct TVCollectionView: View {
    @Bindable var cloudVM: CloudCollectionViewModel

    // Grid 4 columnas optimizado para TV (1920x1080)
    private let columns = [
        GridItem(.fixed(350), spacing: 50),
        GridItem(.fixed(350), spacing: 50),
        GridItem(.fixed(350), spacing: 50),
        GridItem(.fixed(350), spacing: 50)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 80) {
                ForEach(Array(cloudVM.cloudCollection.enumerated()), id: \.element.id) { index, item in
                    NavigationLink(value: item.id) {
                        TVMangaCard(item: item, loadDelay: Double(index) * 0.1)
                    }
                    .buttonStyle(.card)
                }
            }
            .padding(80)
        }
        .navigationTitle("nav_collection")
        .navigationDestination(for: String.self) { itemId in
            if let item = cloudVM.cloudCollection.first(where: { $0.id == itemId }) {
                TVMangaDetailView(item: item) {
                    // Callback cuando se guarda
                    print("[TV] Callback onSave ejecutado")
                }
            }
        }
    }
}
