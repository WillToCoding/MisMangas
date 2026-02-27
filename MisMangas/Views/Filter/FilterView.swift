//
//  FilterView.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct FilterView: View {
    @Binding var filters: MangaFilters
    @State var filterVM = FilterViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if filterVM.state.isLoading {
                    ProgressView("loading_options")
                } else if let errorMessage = filterVM.state.errorMessage {
                    errorView(message: errorMessage)
                } else {
                    filterContent
                }
            }
            .navigationTitle("nav_filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action_cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("action_apply_filters") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .task {
                await filterVM.loadFilterOptions()
            }
        }
    }

    // MARK: - Filter Content

    private var filterContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                searchSection

                if !filterVM.availableDemographics.isEmpty {
                    chipSection(
                        title: "filter_demographics",
                        items: filterVM.availableDemographics,
                        selection: $filters.demographics,
                        color: .purple
                    )
                }

                if !filterVM.availableGenres.isEmpty {
                    chipSection(
                        title: "filter_genres",
                        items: filterVM.availableGenres,
                        selection: $filters.genres,
                        color: .blue
                    )
                }

                if !filterVM.availableThemes.isEmpty {
                    chipSection(
                        title: "filter_themes",
                        items: filterVM.availableThemes,
                        selection: $filters.themes,
                        color: .green
                    )
                }

                advancedSection
                sortSection

                if filters.isActive {
                    clearButton
                }

                Spacer(minLength: 50)
            }
            .padding()
        }
    }
}

// MARK: - Chip Button

struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : color.opacity(0.15), in: Capsule())
                .foregroundStyle(isSelected ? .white : color)
        }
        .buttonStyle(.plain)
        .accessibilitySelectable(label: title, isSelected: isSelected)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var filters = MangaFilters()
    FilterView(filters: $filters)
}
