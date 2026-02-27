//
//  VisionFilterSheet.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 26/02/26.
//

import SwiftUI

struct VisionFilterSheet: View {
    @Binding var filters: MangaFilters
    let filterVM: FilterViewModel
    let onApply: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    demographicsSection
                    Divider()
                    genresSection
                    Divider()
                    scoreSection
                    Divider()
                    statusSection
                    Spacer(minLength: 40)
                }
                .padding(50)
            }
            .navigationTitle("nav_filter")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action_cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if filters.isActive {
                        Button {
                            filters.clear()
                        } label: {
                            Label("action_clear_filters", systemImage: "xmark.circle.fill")
                        }
                        .tint(.red)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onApply()
                    } label: {
                        Label("action_apply_filters", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(minWidth: 900, minHeight: 800)
    }

    // MARK: - Sections

    private var demographicsSection: some View {
        filterSection(title: "filter_demographics", icon: "person.3.fill", color: .purple) {
            VisionChipGroup(
                items: filterVM.availableDemographics,
                selection: $filters.demographics,
                color: .purple
            )
        }
    }

    private var genresSection: some View {
        filterSection(title: "filter_genres", icon: "tag.fill", color: .blue) {
            VisionChipGroup(
                items: filterVM.availableGenres,
                selection: $filters.genres,
                color: .blue
            )
        }
    }

    private var scoreSection: some View {
        filterSection(title: "filter_min_score", icon: "star.fill", color: .yellow) {
            HStack(spacing: 12) {
                ForEach([nil, 7.0, 7.5, 8.0, 8.5, 9.0], id: \.self) { score in
                    Button {
                        filters.minScore = score
                    } label: {
                        Text(score == nil ? "Any" : "≥ \(score!.formatted(.number.precision(.fractionLength(1))))")
                            .font(.title3)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(filters.minScore == score ? Color.yellow : Color.yellow.opacity(0.2), in: Capsule())
                            .foregroundStyle(filters.minScore == score ? .black : .yellow)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var statusSection: some View {
        filterSection(title: "filter_status", icon: "clock.fill", color: .green) {
            HStack(spacing: 12) {
                Button {
                    filters.status = nil
                } label: {
                    Text("Any")
                        .font(.title3)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(filters.status == nil ? Color.green : Color.green.opacity(0.2), in: Capsule())
                        .foregroundStyle(filters.status == nil ? .white : .green)
                }
                .buttonStyle(.plain)

                ForEach([MangaStatus.publishing, .complete, .hiatus], id: \.self) { status in
                    Button {
                        filters.status = status
                    } label: {
                        Text(status.localizedName)
                            .font(.title3)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(filters.status == status ? Color.green : Color.green.opacity(0.2), in: Capsule())
                            .foregroundStyle(filters.status == status ? .white : .green)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Helper

    private func filterSection<Content: View>(
        title: LocalizedStringKey,
        icon: String,
        color: Color,
        content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Label(title, systemImage: icon)
                .font(.title2.bold())
                .foregroundStyle(color)
            content()
        }
    }
}

#Preview {
    @Previewable @State var filters = MangaFilters()

    VisionFilterSheet(
        filters: $filters,
        filterVM: FilterViewModel(),
        onApply: { }
    )
}
