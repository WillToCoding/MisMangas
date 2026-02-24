//
//  TVCollectionView.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct TVCollectionView: View {
    @Bindable var cloudVM: CloudCollectionViewModel

    private let demographicConfig: [(key: String, title: LocalizedStringKey, icon: String, color: Color)] = [
        ("Shounen", "section_shounen", "flame.fill", .orange),
        ("Seinen", "section_seinen", "person.fill", .purple),
        ("Shoujo", "section_shoujo", "heart.fill", .pink),
        ("Josei", "section_josei", "sparkles", .indigo),
        ("Kids", "section_kids", "star.fill", .yellow)
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 60) {
                // Secciones por demografía
                ForEach(demographicConfig, id: \.key) { config in
                    let items = cloudVM.cloudCollection.filter { item in
                        item.manga.demographics.contains { $0.demographic == config.key }
                    }
                    if !items.isEmpty {
                        TVCollectionSection(
                            title: config.title,
                            icon: config.icon,
                            color: config.color
                        ) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                NavigationLink(value: item) {
                                    TVCollectionCardLabel(item: item, loadDelay: Double(index) * 0.1)
                                }
                                .buttonStyle(.card)
                            }
                        }
                    }
                }

                // Mangas sin demografía
                let otherItems = cloudVM.cloudCollection.filter { $0.manga.demographics.isEmpty }
                if !otherItems.isEmpty {
                    TVCollectionSection(
                        title: "section_other",
                        icon: "square.grid.2x2",
                        color: .gray
                    ) {
                        ForEach(Array(otherItems.enumerated()), id: \.element.id) { index, item in
                            NavigationLink(value: item) {
                                TVCollectionCardLabel(item: item, loadDelay: Double(index) * 0.1)
                            }
                            .buttonStyle(.card)
                        }
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.vertical, 50)
        }
        .navigationTitle("nav_collection")
        .navigationDestination(for: UserMangaCollection.self) { item in
            TVMangaDetailView(item: item) {
                Task {
                    await cloudVM.loadCollection()
                }
            }
        }
    }
}

// MARK: - Collection Section

struct TVCollectionSection<Content: View>: View {
    let title: LocalizedStringKey
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Header
            Label(title, systemImage: icon)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(color)
                .padding(.horizontal, 80)

            // Horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 40) {
                    content()
                }
                .padding(.horizontal, 80)
            }
            .focusSection()
        }
    }
}

// MARK: - Collection Card Label

struct TVCollectionCardLabel: View {
    let item: UserMangaCollection
    let loadDelay: Double

    @State private var coverVM = MangaCoverVM()
    @State private var shouldLoad = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Portada
            ZStack(alignment: .topTrailing) {
                Group {
                    if let image = coverVM.image {
                        #if os(tvOS)
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
                                        .font(.system(size: 50))
                                        .foregroundStyle(.secondary)
                                }
                            }
                    }
                }
                .frame(width: 250, height: 375)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Badge de estado
                statusBadge
                    .padding(12)
            }

            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(item.manga.title)
                    .font(.system(size: 24, weight: .bold))
                    .lineLimit(2)
                    .frame(width: 250, alignment: .leading)

                // Progreso
                if let total = item.manga.volumes {
                    let reading = item.readingVolume ?? 1
                    HStack(spacing: 8) {
                        Text("Vol. \(reading)/\(total)")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(Int((Double(reading) / Double(total)) * 100))%")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.blue)
                    }
                    .frame(width: 250)

                    ProgressView(value: Double(reading), total: Double(total))
                        .frame(width: 250)
                        .tint(.blue)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                        Text("status_publishing")
                    }
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(loadDelay))
                shouldLoad = true
                coverVM.getImage(url: item.manga.coverURL)
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        // Solo mostrar badge de colección completa si realmente tiene todos los volúmenes
        if let total = item.manga.volumes, item.volumesOwned.count >= total {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .padding(8)
                .background(.green, in: Circle())
        } else if let reading = item.readingVolume, reading > 1 {
            Image(systemName: "book.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .padding(8)
                .background(.blue, in: Circle())
        }
    }
}

#Preview {
    let authVM = AuthViewModel()
    return TVCollectionView(cloudVM: CloudCollectionViewModel(authVM: authVM))
}
