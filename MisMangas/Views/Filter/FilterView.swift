//
//  FilterView.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct FilterView: View {
    @Binding var filters: MangaFilters
    @State private var filterVM = FilterViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if filterVM.isLoading {
                    ProgressView("loading_options")
                } else if let errorMessage = filterVM.errorMessage {
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
                // Búsqueda
                searchSection

                // Demografías
                if !filterVM.availableDemographics.isEmpty {
                    chipSection(
                        title: "filter_demographics",
                        items: filterVM.availableDemographics,
                        selection: $filters.demographics,
                        color: .purple
                    )
                }

                // Géneros
                if !filterVM.availableGenres.isEmpty {
                    chipSection(
                        title: "filter_genres",
                        items: filterVM.availableGenres,
                        selection: $filters.genres,
                        color: .blue
                    )
                }

                // Temáticas
                if !filterVM.availableThemes.isEmpty {
                    chipSection(
                        title: "filter_themes",
                        items: filterVM.availableThemes,
                        selection: $filters.themes,
                        color: .green
                    )
                }

                // Filtros avanzados
                advancedSection

                // Ordenar por
                sortSection

                // Limpiar
                if filters.isActive {
                    clearButton
                }

                Spacer(minLength: 50)
            }
            .padding()
        }
    }

    // MARK: - Search Section

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("filter_search", systemImage: "magnifyingglass")
                .font(.headline)

            TextField("search_placeholder", text: $filters.searchText)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Chip Section

    private func chipSection(
        title: LocalizedStringKey,
        items: [String],
        selection: Binding<Set<String>>,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                if !selection.wrappedValue.isEmpty {
                    Text("(\(selection.wrappedValue.count))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            FlowLayout(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    ChipButton(
                        title: localizedAPIValue(item),
                        isSelected: selection.wrappedValue.contains(item),
                        color: color
                    ) {
                        if selection.wrappedValue.contains(item) {
                            selection.wrappedValue.remove(item)
                        } else {
                            selection.wrappedValue.insert(item)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("filter_advanced", systemImage: "slider.horizontal.3")
                .font(.headline)

            // Año
            HStack {
                Text("filter_year")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: $filters.startYear) {
                    Text("filter_any").tag(nil as Int?)
                    ForEach((1950...2025).reversed(), id: \.self) { year in
                        Text(String(year)).tag(year as Int?)
                    }
                }
                .pickerStyle(.menu)
            }

            // Score mínimo
            HStack {
                Text("filter_min_score")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: $filters.minScore) {
                    Text("filter_any").tag(nil as Double?)
                    ForEach([6.0, 7.0, 7.5, 8.0, 8.5, 9.0], id: \.self) { score in
                        Text("≥ \(String(format: "%.1f", score))").tag(score as Double?)
                    }
                }
                .pickerStyle(.menu)
            }

            // Estado
            HStack {
                Text("filter_status")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: $filters.status) {
                    Text("filter_any").tag(nil as MangaStatus?)
                    ForEach(MangaStatus.allCases, id: \.self) { status in
                        Text(status.localizedName).tag(status as MangaStatus?)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Sort Section

    private var sortSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("filter_sort", systemImage: "arrow.up.arrow.down")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    ChipButton(
                        title: option.localizedName,
                        isSelected: filters.sortBy == option,
                        color: .orange
                    ) {
                        filters.sortBy = option
                    }
                }
            }
        }
    }

    // MARK: - Clear Button

    private var clearButton: some View {
        Button {
            filters.clear()
        } label: {
            Label("action_clear_filters", systemImage: "xmark.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.red)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("error_title", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("action_retry") {
                Task {
                    await filterVM.loadFilterOptions()
                }
            }
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
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var filters = MangaFilters()
    FilterView(filters: $filters)
}
