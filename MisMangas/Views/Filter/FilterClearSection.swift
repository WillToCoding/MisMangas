//
//  FilterClearSection.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct FilterClearSection: View {
    @Binding var filters: MangaFilters

    var body: some View {
        Section {
            Button(role: .destructive) {
                #if os(iOS)
                HapticFeedback.warning.trigger()
                #endif
                filters.clear()
            } label: {
                HStack {
                    Spacer()
                    Label("action_clear_filters", systemImage: "xmark.circle.fill")
                    Spacer()
                }
            }
            .disabled(!filters.isActive)
            .accessibilityHint(String(localized: "accessibility_clear_all_filters_hint"))
        }
    }
}

#Preview {
    @Previewable @State var filters = MangaFilters()
    Form {
        FilterClearSection(filters: $filters)
    }
}
