//
//  FilterToggleSection.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

/// Sección genérica de filtros con toggles (para géneros, demografías, temáticas)
struct FilterToggleSection: View {
    let title: LocalizedStringKey
    let accessibilityTitle: String
    let items: [String]
    @Binding var selectedItems: Set<String>

    var body: some View {
        if !items.isEmpty {
            Section {
                ForEach(items, id: \.self) { item in
                    Toggle(localizedAPIValue(item), isOn: binding(for: item))
                }
            } header: {
                headerView
            }
        }
    }

    private func binding(for item: String) -> Binding<Bool> {
        Binding(
            get: { selectedItems.contains(item) },
            set: { isOn in
                if isOn {
                    selectedItems.insert(item)
                } else {
                    selectedItems.remove(item)
                }
            }
        )
    }

    private var headerView: some View {
        HStack {
            Text(title)
            if !selectedItems.isEmpty {
                Text("(\(selectedItems.count))")
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityHeader(.h2)
        .accessibilityLabel(accessibilityTitle + (selectedItems.isEmpty ? "" : ", \(selectedItems.count) " + String(localized: "accessibility_selected")))
    }
}

// MARK: - Convenience initializers
extension FilterToggleSection {
    /// Inicializador para géneros
    static func genres(items: [String], selection: Binding<Set<String>>) -> FilterToggleSection {
        FilterToggleSection(
            title: "filter_genres",
            accessibilityTitle: String(localized: "accessibility_genres"),
            items: items,
            selectedItems: selection
        )
    }

    /// Inicializador para demografías
    static func demographics(items: [String], selection: Binding<Set<String>>) -> FilterToggleSection {
        FilterToggleSection(
            title: "filter_demographics",
            accessibilityTitle: String(localized: "accessibility_demographics"),
            items: items,
            selectedItems: selection
        )
    }

    /// Inicializador para temáticas
    static func themes(items: [String], selection: Binding<Set<String>>) -> FilterToggleSection {
        FilterToggleSection(
            title: "filter_themes",
            accessibilityTitle: String(localized: "accessibility_themes"),
            items: items,
            selectedItems: selection
        )
    }
}

#Preview {
    @Previewable @State var selection: Set<String> = ["Action", "Comedy"]
    Form {
        FilterToggleSection.genres(
            items: ["Action", "Adventure", "Comedy", "Drama"],
            selection: $selection
        )
    }
}
