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
                    ContentUnavailableView {
                        Label("error_title", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("action_retry") {
                            Task {
                                await filterVM.loadFilterOptions()
                            }
                        }
                    }
                } else {
                    filterForm
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
                // Cargar opciones al aparecer
                await filterVM.loadFilterOptions()
            }
        }
    }

    private var filterForm: some View {
        Form {
            // MARK: - Búsqueda por Texto
            Section {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("search_placeholder", text: $filters.searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if !filters.searchText.isEmpty {
                        Button {
                            filters.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("filter_search")
            } footer: {
                if !filters.searchText.isEmpty {
                    Text("\"\(filters.searchText)\"")
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - Filtros Avanzados (Jikan)
            Section {
                // Puntuación mínima
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("filter_min_score")
                        Spacer()
                        if let score = filters.minScore {
                            Text(String(format: "%.1f", score))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("filter_any")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Slider(
                        value: Binding(
                            get: { filters.minScore ?? 0 },
                            set: { filters.minScore = $0 > 0 ? $0 : nil }
                        ),
                        in: 0...10,
                        step: 0.5
                    )

                    HStack {
                        Image(systemName: "star")
                            .font(.caption)
                        Spacer()
                        Image(systemName: "star.fill")
                            .font(.caption)
                    }
                    .foregroundStyle(.yellow)
                }

                // Rango de años
                HStack {
                    Text("filter_year_from")
                    Spacer()
                    Picker("", selection: Binding(
                        get: { filters.startYear ?? 0 },
                        set: { filters.startYear = $0 > 0 ? $0 : nil }
                    )) {
                        Text("filter_any").tag(0)
                        ForEach((1950...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .labelsHidden()
                }

                HStack {
                    Text("filter_year_to")
                    Spacer()
                    Picker("", selection: Binding(
                        get: { filters.endYear ?? 0 },
                        set: { filters.endYear = $0 > 0 ? $0 : nil }
                    )) {
                        Text("filter_any").tag(0)
                        ForEach((1950...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .labelsHidden()
                }

                // Estado
                Picker("filter_status", selection: Binding(
                    get: { filters.status ?? .publishing },
                    set: { newValue in
                        // Si el status actual es nil, cualquier selección lo activa
                        // Si ya es el mismo valor, lo desactiva
                        if filters.status == newValue {
                            filters.status = nil
                        } else {
                            filters.status = newValue
                        }
                    }
                )) {
                    ForEach(MangaStatus.allCases, id: \.self) { status in
                        Text(status.localizedName).tag(status)
                    }
                }

                if filters.status != nil {
                    Button("filter_clear_status") {
                        filters.status = nil
                    }
                    .foregroundStyle(.red)
                }
            } header: {
                HStack {
                    Text("filter_advanced")
                    if filters.hasAdvancedFilters {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.yellow)
                    }
                }
            } footer: {
                if filters.hasAdvancedFilters {
                    Text("filter_advanced_note")
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - Géneros
            if !filterVM.availableGenres.isEmpty {
                Section {
                    ForEach(filterVM.availableGenres, id: \.self) { genre in
                        Toggle(localizedAPIValue(genre), isOn: Binding(
                            get: { filters.genres.contains(genre) },
                            set: { isOn in
                                if isOn {
                                    filters.genres.insert(genre)
                                } else {
                                    filters.genres.remove(genre)
                                }
                            }
                        ))
                    }
                } header: {
                    HStack {
                        Text("filter_genres")
                        if !filters.genres.isEmpty {
                            Text("(\(filters.genres.count))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // MARK: - Demografías
            if !filterVM.availableDemographics.isEmpty {
                Section {
                    ForEach(filterVM.availableDemographics, id: \.self) { demographic in
                        Toggle(localizedAPIValue(demographic), isOn: Binding(
                            get: { filters.demographics.contains(demographic) },
                            set: { isOn in
                                if isOn {
                                    filters.demographics.insert(demographic)
                                } else {
                                    filters.demographics.remove(demographic)
                                }
                            }
                        ))
                    }
                } header: {
                    HStack {
                        Text("filter_demographics")
                        if !filters.demographics.isEmpty {
                            Text("(\(filters.demographics.count))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // MARK: - Temáticas
            if !filterVM.availableThemes.isEmpty {
                Section {
                    ForEach(filterVM.availableThemes, id: \.self) { theme in
                        Toggle(localizedAPIValue(theme), isOn: Binding(
                            get: { filters.themes.contains(theme) },
                            set: { isOn in
                                if isOn {
                                    filters.themes.insert(theme)
                                } else {
                                    filters.themes.remove(theme)
                                }
                            }
                        ))
                    }
                } header: {
                    HStack {
                        Text("filter_themes")
                        if !filters.themes.isEmpty {
                            Text("(\(filters.themes.count))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // MARK: - Ordenamiento
            Section("sort_by") {
                Picker("sort_order", selection: $filters.sortBy) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.localizedName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            // MARK: - Limpiar Filtros
            Section {
                Button(role: .destructive) {
                    filters.clear()
                } label: {
                    HStack {
                        Spacer()
                        Label("action_clear_filters", systemImage: "xmark.circle.fill")
                        Spacer()
                    }
                }
                .disabled(!filters.isActive)
            }
        }
    }
}

// MARK: - Preview
#Preview("Sin filtros") {
    @Previewable @State var filters = MangaFilters()

    FilterView(filters: $filters)
}

#Preview("Con filtros activos") {
    @Previewable @State var filters = MangaFilters()

    FilterView(filters: $filters)
        .onAppear {
            filters.genres.insert("Action")
            filters.genres.insert("Adventure")
            filters.demographics.insert("Shounen")
        }
}
