//
//  FilterSortSection.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct FilterSortSection: View {
    @Binding var sortBy: SortOption

    var body: some View {
        Section {
            Picker("sort_order", selection: $sortBy) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.localizedName).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(String(localized: "accessibility_sort_order"))
        } header: {
            Text("sort_by")
                .accessibilityHeader(.h2)
        }
    }
}

#Preview {
    @Previewable @State var sortBy: SortOption = .score
    Form {
        FilterSortSection(sortBy: $sortBy)
    }
}
