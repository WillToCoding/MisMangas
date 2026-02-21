//
//  PreviewContainer.swift
//  MisMangas
//
//  Created by Juan Carlos on 20/2/26.
//

import SwiftUI
import SwiftData

/// PreviewModifier reutilizable para configurar previews con SwiftData y ViewModels.
///
/// Uso:
/// ```swift
/// #Preview(traits: .sampleData) {
///     HomeView()
/// }
/// ```
struct PreviewContainer: PreviewModifier {

    static func makeSharedContext() async throws -> ModelContainer {
        PreviewData.shared.container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        let authVM = AuthViewModel()
        content
            .modelContainer(context)
            .environment(authVM)
            .environment(CloudCollectionViewModel(authVM: authVM))
    }
}

// MARK: - Preview Trait

extension PreviewTrait where T == Preview.ViewTraits {
    /// Trait para previews con SwiftData y ViewModels configurados.
    @MainActor static var sampleData: Self = .modifier(PreviewContainer())
}
