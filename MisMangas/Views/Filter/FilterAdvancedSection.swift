//
//  FilterAdvancedSection.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct FilterAdvancedSection: View {
    @Binding var filters: MangaFilters

    var body: some View {
        Section {
            scoreSlider
            yearFromPicker
            yearToPicker
            statusPicker
            clearStatusButton
        } header: {
            headerView
        } footer: {
            if filters.hasAdvancedFilters {
                Text("filter_advanced_note")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Score Slider
    private var scoreSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("filter_min_score")
                Spacer()
                if let score = filters.minScore {
                    Text(score.formatted(.number.precision(.fractionLength(1))))
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
            .accessibilityLabel(String(localized: "accessibility_min_score"))
            .accessibilityValue(filters.minScore.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? String(localized: "filter_any"))

            HStack {
                Image(systemName: "star")
                    .font(.caption)
                Spacer()
                Image(systemName: "star.fill")
                    .font(.caption)
            }
            .foregroundStyle(.yellow)
            .accessibilityHidden(true)
        }
    }

    // MARK: - Year Pickers
    private var yearFromPicker: some View {
        HStack {
            Text("filter_year_from")
            Spacer()
            Picker("", selection: Binding(
                get: { filters.startYear ?? 0 },
                set: { filters.startYear = $0 > 0 ? $0 : nil }
            )) {
                Text("filter_any").tag(0)
                ForEach((1950...currentYear).reversed(), id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .labelsHidden()
        }
    }

    private var yearToPicker: some View {
        HStack {
            Text("filter_year_to")
            Spacer()
            Picker("", selection: Binding(
                get: { filters.endYear ?? 0 },
                set: { filters.endYear = $0 > 0 ? $0 : nil }
            )) {
                Text("filter_any").tag(0)
                ForEach((1950...currentYear).reversed(), id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .labelsHidden()
        }
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    // MARK: - Status Picker
    private var statusPicker: some View {
        Picker("filter_status", selection: Binding(
            get: { filters.status ?? .publishing },
            set: { newValue in
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
    }

    @ViewBuilder
    private var clearStatusButton: some View {
        if filters.status != nil {
            Button("filter_clear_status") {
                #if os(iOS)
                HapticFeedback.light.trigger()
                #endif
                filters.status = nil
            }
            .foregroundStyle(.red)
            .frame(minHeight: 44)
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("filter_advanced")
            if filters.hasAdvancedFilters {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityAddTraits(.isHeader)
        .accessibilityHeading(.h2)
        .accessibilityLabel(filters.hasAdvancedFilters ? String(localized: "accessibility_advanced_filters_active") : String(localized: "filter_advanced"))
    }
}

#Preview {
    @Previewable @State var filters = MangaFilters()
    Form {
        FilterAdvancedSection(filters: $filters)
    }
}
