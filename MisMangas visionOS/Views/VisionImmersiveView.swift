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

    var body: some View {
        RealityView { content in
            // Crear una galería circular de mangas en 3D
            let radius: Float = 3.0
            let count = min(cloudVM.cloudCollection.count, 12)

            for (index, _) in cloudVM.cloudCollection.prefix(count).enumerated() {
                let angle = Float(index) * (360.0 / Float(count)) * .pi / 180.0
                let x = radius * cos(angle)
                let z = radius * sin(angle)

                // Crear entidad para cada manga
                let entity = ModelEntity(
                    mesh: .generateBox(width: 0.3, height: 0.45, depth: 0.02),
                    materials: [SimpleMaterial(color: .white, isMetallic: false)]
                )

                entity.position = SIMD3(x: x, y: 1.5, z: z)
                entity.look(at: SIMD3(x: 0, y: 1.5, z: 0), from: entity.position, relativeTo: nil)

                content.add(entity)
            }
        }
    }
}
