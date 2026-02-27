//
//  FilterView+Sections.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

// MARK: - Filter Sections

extension FilterView {
    var searchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("filter_search", systemImage: "magnifyingglass")
                .font(.headline)
                .accessibilityHeader(.h2)

            TextField("search_placeholder", text: $filters.searchText)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(String(localized: "accessibility_search_manga"))
        }
    }

    func chipSection(
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
            .accessibilityElement(children: .combine)
            .accessibilityHeader(.h2)

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

    var advancedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("filter_advanced", systemImage: "slider.horizontal.3")
                .font(.headline)
                .accessibilityHeader(.h2)

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

            HStack {
                Text("filter_min_score")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: $filters.minScore) {
                    Text("filter_any").tag(nil as Double?)
                    ForEach([6.0, 7.0, 7.5, 8.0, 8.5, 9.0], id: \.self) { score in
                        Text("≥ \(score.formatted(.number.precision(.fractionLength(1))))").tag(score as Double?)
                    }
                }
                .pickerStyle(.menu)
            }

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

    var sortSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("filter_sort", systemImage: "arrow.up.arrow.down")
                .font(.headline)
                .accessibilityHeader(.h2)

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

    var clearButton: some View {
        Button {
            filters.clear()
        } label: {
            Label("action_clear_filters", systemImage: "xmark.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.red)
        .accessibilityHint(String(localized: "accessibility_clear_all_filters_hint"))
    }

    func errorView(message: String) -> some View {
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
