//
//  VisionImmersiveView.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI
import RealityKit

struct VisionImmersiveView: View {
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @State private var entityPositions: [String: SIMD3<Float>] = [:]

    var body: some View {
        RealityView { content, attachments in
            // Crear una galería circular de mangas en 3D
            let radius: Float = 3.0
            let items = Array(cloudVM.cloudCollection.prefix(12))
            let count = items.count

            for (index, item) in items.enumerated() {
                let angle = Float(index) * (360.0 / Float(max(count, 1))) * .pi / 180.0
                let x = radius * cos(angle)
                let z = radius * sin(angle)

                // Crear entidad base para cada manga
                let entity = Entity()
                entity.name = item.id

                // Posición inicial o guardada
                let position = entityPositions[item.id] ?? SIMD3(x: x, y: 1.5, z: z)
                entity.position = position

                // Orientar hacia el centro
                entity.look(at: SIMD3(x: 0, y: 1.5, z: 0), from: entity.position, relativeTo: nil)

                // Añadir componentes para interacción
                let collisionShape = ShapeResource.generateBox(width: 0.35, height: 0.5, depth: 0.05)
                entity.components.set(CollisionComponent(shapes: [collisionShape]))
                entity.components.set(InputTargetComponent())

                // Añadir attachment de SwiftUI
                if let attachment = attachments.entity(for: item.id) {
                    attachment.position = SIMD3(x: 0, y: 0, z: 0.03)
                    entity.addChild(attachment)
                }

                // Añadir fondo/marco
                let frameMesh = MeshResource.generateBox(width: 0.35, height: 0.5, depth: 0.02, cornerRadius: 0.02)
                let frameMaterial = SimpleMaterial(color: .white, isMetallic: false)
                let frameEntity = ModelEntity(mesh: frameMesh, materials: [frameMaterial])
                entity.addChild(frameEntity)

                content.add(entity)
            }
        } update: { content, attachments in
            // Actualizar posiciones cuando cambien
            for entity in content.entities {
                if let storedPosition = entityPositions[entity.name] {
                    entity.position = storedPosition
                }
            }
        } attachments: {
            // Crear vistas SwiftUI para cada manga
            ForEach(Array(cloudVM.cloudCollection.prefix(12))) { item in
                Attachment(id: item.id) {
                    ImmersiveMangaCard(item: item)
                }
            }
        }
        .gesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    // Mover la entidad mientras se arrastra
                    let entity = value.entity
                    let translation = value.convert(value.translation3D, from: .local, to: .scene)

                    // Calcular nueva posición basada en el arrastre
                    let startPosition = entityPositions[entity.name] ?? entity.position
                    entity.position = startPosition + SIMD3<Float>(
                        Float(translation.x),
                        Float(translation.y),
                        Float(translation.z)
                    )
                }
                .onEnded { value in
                    // Guardar la posición final
                    let entity = value.entity
                    entityPositions[entity.name] = entity.position
                }
        )
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    // Al tocar, traer el manga más cerca
                    let entity = value.entity
                    withAnimation {
                        // Mover hacia el usuario (z más cercano)
                        var newPosition = entity.position
                        newPosition.z = newPosition.z > 1.0 ? 0.5 : 2.0
                        newPosition.y = 1.5
                        entityPositions[entity.name] = newPosition
                        entity.position = newPosition
                    }
                }
        )
    }
}

// MARK: - Immersive Manga Card
struct ImmersiveMangaCard: View {
    let item: UserMangaCollection
    @State private var coverVM = MangaCoverVM()

    var body: some View {
        VStack(spacing: 8) {
            // Portada
            Group {
                if let image = coverVM.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .overlay {
                            if coverVM.isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "photo")
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
            }
            .frame(width: 120, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Info
            VStack(spacing: 4) {
                Text(item.manga.title)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .frame(width: 120)

                if let total = item.manga.volumes {
                    let reading = item.readingVolume ?? 1
                    HStack(spacing: 4) {
                        Image(systemName: "book.fill")
                            .font(.caption2)
                        Text("Vol. \(reading)/\(total)")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .task {
            coverVM.getImage(url: item.manga.coverURL)
        }
    }
}
