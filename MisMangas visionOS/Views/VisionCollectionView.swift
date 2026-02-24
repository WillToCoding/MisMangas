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

    private let demographicConfig: [(key: String, title: LocalizedStringKey, icon: String, color: Color)] = [
        ("Shounen", "section_shounen", "flame.fill", .orange),
        ("Seinen", "section_seinen", "person.fill", .purple),
        ("Shoujo", "section_shoujo", "heart.fill", .pink),
        ("Josei", "section_josei", "sparkles", .indigo),
        ("Kids", "section_kids", "star.fill", .yellow)
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 50) {
                // Secciones por demografía
                ForEach(demographicConfig, id: \.key) { config in
                    let items = cloudVM.cloudCollection.filter { item in
                        item.manga.demographics.contains { $0.demographic == config.key }
                    }
                    if !items.isEmpty {
                        VisionHorizontalSection(
                            title: config.title,
                            icon: config.icon,
                            color: config.color
                        ) {
                            ForEach(items) { item in
                                NavigationLink(value: item.id) {
                                    VisionCollectionCard(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Mangas sin demografía
                let otherItems = cloudVM.cloudCollection.filter { $0.manga.demographics.isEmpty }
                if !otherItems.isEmpty {
                    VisionHorizontalSection(
                        title: "section_other",
                        icon: "square.grid.2x2",
                        color: .gray
                    ) {
                        ForEach(otherItems) { item in
                            NavigationLink(value: item.id) {
                                VisionCollectionCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer(minLength: 60)
            }
            .padding(.vertical, 40)
        }
        .navigationTitle("nav_collection")
        .navigationDestination(for: String.self) { itemId in
            if let item = cloudVM.cloudCollection.first(where: { $0.id == itemId }) {
                VisionMangaDetailView(item: item) {
                    Task {
                        await cloudVM.loadCollection()
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
            if cloudVM.state.isLoading {
                ProgressView()
                    .padding()
                    .glassBackgroundEffect()
            }
        }
    }
}

// MARK: - Vision Horizontal Section
struct VisionHorizontalSection<Content: View>: View {
    let title: LocalizedStringKey
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            Label(title, systemImage: icon)
                .font(.title.bold())
                .foregroundStyle(color)
                .padding(.horizontal, 60)

            // Horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    content()
                }
                .padding(.horizontal, 60)
            }
        }
    }
}

// MARK: - Vision Collection Card
struct VisionCollectionCard: View {
    let item: UserMangaCollection
    @State private var coverVM = MangaCoverVM()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Portada
            ZStack(alignment: .topTrailing) {
                Group {
                    if let image = coverVM.image {
                        #if os(visionOS)
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        #endif
                    } else {
                        Rectangle()
                            .fill(.gray.opacity(0.3))
                            .overlay {
                                if coverVM.isLoading {
                                    ProgressView()
                                } else {
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                }
                            }
                    }
                }
                .frame(width: 200, height: 300)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Badge de estado
                if let total = item.manga.volumes, item.volumesOwned.count >= total {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.green, in: Circle())
                        .padding(8)
                } else if let reading = item.readingVolume, reading > 1 {
                    Image(systemName: "book.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.blue, in: Circle())
                        .padding(8)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(item.manga.title)
                    .font(.headline)
                    .lineLimit(2)
                    .frame(width: 200, alignment: .leading)

                if let total = item.manga.volumes {
                    let reading = item.readingVolume ?? 1
                    HStack {
                        Text("Vol. \(reading)/\(total)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(Int((Double(reading) / Double(total)) * 100))%")
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                    }
                    .frame(width: 200)

                    ProgressView(value: Double(reading), total: Double(total))
                        .frame(width: 200)
                        .tint(.blue)
                }
            }
        }
        .task {
            coverVM.getImage(url: item.manga.coverURL)
        }
    }
}
