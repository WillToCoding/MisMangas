//
//  ModelContainer+Extension.swift
//  MisMangas
//
//  Created by Juan Carlos on 4/12/25.
//

import Foundation
import SwiftData

extension ModelContainer {
    /// Container para Preview en SwiftUI
    @MainActor
    static var preview: ModelContainer {
        PreviewData.shared.container
    }

    /// Container para producción
    static var production: ModelContainer {
        let schema = Schema([Model.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
