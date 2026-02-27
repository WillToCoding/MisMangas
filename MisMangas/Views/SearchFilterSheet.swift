//
//  SearchFilterSheet.swift
//  MisMangas
//
//  Created by Juan Carlos on 26/2/26.
//

import SwiftUI

/// Sheet de filtros para la búsqueda de mangas
struct SearchFilterSheet: View {
    @Binding var filters: MangaFilters
    @Binding var isPresented: Bool
    let filterOptionsVM: FilterViewModel
    let onApply: () -> Void

    var body: some View {
        NavigationStack {
            List {
                demographicsSection
                sortSection

                if !filterOptionsVM.availableGenres.isEmpty {
                    genresSection
                }

                if !filterOptionsVM.availableThemes.isEmpty {
                    themesSection
                }
            }
            .navigationTitle("filter_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action_cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        isPresented = false
                        onApply()
                    } label: {
                        Text("action_apply_filters")
                            .bold()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Demographics Section

    private var demographicsSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(DemographicsConfig.list) { config in
                        let isSelected = filters.demographics.contains(config.id)
                        Button {
                            if isSelected {
                                filters.demographics.remove(config.id)
                            } else {
                                filters.demographics.removeAll()
                                filters.demographics.insert(config.id)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: config.icon)
                                    .foregroundStyle(config.color)
                                Text(config.title)
                                    .lineLimit(1)
                                    .fixedSize()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                isSelected
                                    ? config.color.opacity(0.2)
                                    : Color.gray.opacity(0.1),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        isSelected
                                            ? config.color
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilitySelectable(label: config.id, isSelected: isSelected)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("filter_demographics")
        }
    }

    // MARK: - Sort Section

    private var sortSection: some View {
        Section {
            Picker("sort_by", selection: $filters.sortBy) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.localizedName).tag(option)
                }
            }
        }
    }

    // MARK: - Genres Section

    private var genresSection: some View {
        Section {
            FlowLayout(spacing: 8) {
                ForEach(filterOptionsVM.availableGenres, id: \.self) { genre in
                    FilterChipView(
                        title: localizedAPIValue(genre),
                        isSelected: filters.genres.contains(genre),
                        color: .blue
                    ) {
                        if filters.genres.contains(genre) {
                            filters.genres.remove(genre)
                        } else {
                            filters.genres.insert(genre)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            HStack {
                Text("filter_genres")
                if !filters.genres.isEmpty {
                    Text("\(filters.genres.count)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
        }
    }

    // MARK: - Themes Section

    private var themesSection: some View {
        Section {
            FlowLayout(spacing: 8) {
                ForEach(filterOptionsVM.availableThemes, id: \.self) { theme in
                    FilterChipView(
                        title: localizedAPIValue(theme),
                        isSelected: filters.themes.contains(theme),
                        color: .purple
                    ) {
                        if filters.themes.contains(theme) {
                            filters.themes.remove(theme)
                        } else {
                            filters.themes.insert(theme)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            HStack {
                Text("filter_themes")
                if !filters.themes.isEmpty {
                    Text("\(filters.themes.count)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.purple, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var filters = MangaFilters()
    @Previewable @State var isPresented = true

    SearchFilterSheet(
        filters: $filters,
        isPresented: $isPresented,
        filterOptionsVM: FilterViewModel(),
        onApply: {}
    )
}
