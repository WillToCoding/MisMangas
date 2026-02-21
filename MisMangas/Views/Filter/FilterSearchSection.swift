//
//  FilterSearchSection.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct FilterSearchSection: View {
    @Binding var searchText: String

    var body: some View {
        Section {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                TextField("search_placeholder", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel(String(localized: "accessibility_search_manga"))

                if !searchText.isEmpty {
                    clearButton
                }
            }
        } header: {
            Text("filter_search")
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)
        } footer: {
            if !searchText.isEmpty {
                Text("\"\(searchText)\"")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var clearButton: some View {
        Button {
            #if os(iOS)
            HapticFeedback.light.trigger()
            #endif
            searchText = ""
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.secondary)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(String(localized: "accessibility_clear_search"))
    }
}

#Preview {
    @Previewable @State var searchText = "One Piece"
    Form {
        FilterSearchSection(searchText: $searchText)
    }
}
