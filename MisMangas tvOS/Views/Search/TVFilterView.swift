//
//  TVFilterView.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 22/2/26.
//

import SwiftUI

struct TVFilterView: View {
    @Binding var filters: MangaFilters
    @Environment(\.dismiss) private var dismiss
    @State private var filterVM = FilterViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 50) {
                    if filterVM.state.isLoading {
                        HStack {
                            Spacer()
                            ProgressView("loading_options")
                                .font(.title2)
                            Spacer()
                        }
                        .padding(.top, 100)
                    } else {
                        // Demografías
                        if !filterVM.availableDemographics.isEmpty {
                            filterSection(
                                title: "filter_demographics",
                                icon: "person.3.fill",
                                color: .purple
                            ) {
                                TVChipGroup(
                                    items: filterVM.availableDemographics,
                                    selection: $filters.demographics,
                                    color: .purple
                                )
                            }
                        }

                        // Géneros (solo los más populares para no saturar)
                        if !filterVM.availableGenres.isEmpty {
                            filterSection(
                                title: "filter_genres",
                                icon: "tag.fill",
                                color: .blue
                            ) {
                                TVChipGroup(
                                    items: Array(filterVM.availableGenres.prefix(12)),
                                    selection: $filters.genres,
                                    color: .blue
                                )
                            }
                        }

                        // Score mínimo
                        filterSection(
                            title: "filter_min_score",
                            icon: "star.fill",
                            color: .yellow
                        ) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    TVOptionButton(
                                        isSelected: filters.minScore == nil,
                                        color: .yellow,
                                        label: "Any"
                                    ) {
                                        filters.minScore = nil
                                    }
                                    ForEach([7.0, 7.5, 8.0, 8.5, 9.0], id: \.self) { score in
                                        TVOptionButton(
                                            isSelected: filters.minScore == score,
                                            color: .yellow,
                                            label: "≥ \(score.formatted(.number.precision(.fractionLength(1))))"
                                        ) {
                                            filters.minScore = score
                                        }
                                    }
                                }
                            }
                            .environment(\.layoutDirection, .leftToRight)
                            .focusSection()
                        }

                        // Estado
                        filterSection(
                            title: "filter_status",
                            icon: "clock.fill",
                            color: .green
                        ) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    TVOptionButton(
                                        isSelected: filters.status == nil,
                                        color: .green,
                                        label: "Any"
                                    ) {
                                        filters.status = nil
                                    }
                                    TVOptionButton(
                                        isSelected: filters.status == .publishing,
                                        color: .green,
                                        label: "Publishing"
                                    ) {
                                        filters.status = .publishing
                                    }
                                    TVOptionButton(
                                        isSelected: filters.status == .complete,
                                        color: .green,
                                        label: "Finished"
                                    ) {
                                        filters.status = .complete
                                    }
                                    TVOptionButton(
                                        isSelected: filters.status == .hiatus,
                                        color: .green,
                                        label: "On Hiatus"
                                    ) {
                                        filters.status = .hiatus
                                    }
                                }
                            }
                            .environment(\.layoutDirection, .leftToRight)
                            .focusSection()
                        }

                        // Botones de acción
                        HStack(spacing: 40) {
                            if filters.isActive {
                                Button {
                                    filters.clear()
                                } label: {
                                    Label("action_clear_filters", systemImage: "xmark.circle.fill")
                                        .font(.system(size: 28, weight: .semibold))
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }

                            Button {
                                dismiss()
                            } label: {
                                Label("action_apply_filters", systemImage: "checkmark.circle.fill")
                                    .font(.system(size: 28, weight: .semibold))
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.top, 30)
                    }

                    Spacer(minLength: 100)
                }
                .padding(60)
            }
            .navigationTitle("nav_filter")
            .task {
                await filterVM.loadFilterOptions()
            }
        }
    }

    // MARK: - Filter Section
    private func filterSection<Content: View>(
        title: LocalizedStringKey,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Label(title, systemImage: icon)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(color)

            content()
        }
        .padding(30)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - TV Chip Group
struct TVChipGroup: View {
    let items: [String]
    @Binding var selection: Set<String>
    let color: Color

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(items, id: \.self) { item in
                    Button {
                        if selection.contains(item) {
                            selection.remove(item)
                        } else {
                            selection.insert(item)
                        }
                    } label: {
                        Text(localizedAPIValue(item))
                            .font(.system(size: 26, weight: .medium))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                selection.contains(item) ? color : color.opacity(0.2),
                                in: Capsule()
                            )
                            .foregroundStyle(selection.contains(item) ? .white : color)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .focusSection()
    }
}

// MARK: - TV Option Button
struct TVOptionButton: View {
    let isSelected: Bool
    let color: Color
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 26, weight: .medium))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    isSelected ? color : color.opacity(0.2),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? (color == .yellow ? .black : .white) : color)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var filters = MangaFilters()
    TVFilterView(filters: $filters)
}
