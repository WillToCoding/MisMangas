//
//  SyncConflictView.swift
//  MisMangas
//
//  Created by Juan Carlos on 22/2/26.
//

import SwiftUI

/// Vista para resolver conflictos de sincronizacion entre local y cloud
struct SyncConflictView: View {
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("sync_conflict_explanation")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(cloudVM.syncConflicts) { conflict in
                    ConflictRow(conflict: conflict)
                }
            }
            .navigationTitle("sync_conflicts_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("action_done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Conflict Row

private struct ConflictRow: View {
    let conflict: SyncConflict
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @State private var isResolving = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Titulo del manga
            Text(conflict.mangaTitle)
                .font(.headline)
                .accessibilityHeader()

            // Comparacion Local vs Cloud
            HStack(spacing: 16) {
                // Local
                VStack(alignment: .leading, spacing: 4) {
                    Label("sync_local", systemImage: "iphone")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)

                    Text("sync_volumes \(conflict.localVolumesOwned.count)")
                        .font(.caption)

                    if let vol = conflict.localReadingVolume {
                        Text("sync_reading \(vol)")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(localAccessibilityLabel)

                Divider()
                    .accessibilityHidden(true)

                // Cloud
                VStack(alignment: .leading, spacing: 4) {
                    Label("sync_cloud", systemImage: "cloud")
                        .font(.caption.bold())
                        .foregroundStyle(.purple)

                    Text("sync_volumes \(conflict.cloudVolumesOwned.count)")
                        .font(.caption)

                    if let vol = conflict.cloudReadingVolume {
                        Text("sync_reading \(vol)")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(cloudAccessibilityLabel)
            }
            .padding(.vertical, 8)

            // Botones de resolucion
            HStack(spacing: 12) {
                Button {
                    resolveKeepLocal()
                } label: {
                    Label("sync_keep_local", systemImage: "iphone")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .accessibilityHint(String(localized: "accessibility_keep_local_hint"))

                Button {
                    resolveUseCloud()
                } label: {
                    Label("sync_use_cloud", systemImage: "cloud")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.purple)
                .accessibilityHint(String(localized: "accessibility_use_cloud_hint"))
            }
            .disabled(isResolving)
        }
        .padding(.vertical, 4)
    }

    private var localAccessibilityLabel: String {
        var label = String(localized: "sync_local") + ", "
        label += String(localized: "accessibility_volumes_count \(conflict.localVolumesOwned.count)")
        if let vol = conflict.localReadingVolume {
            label += ", " + String(localized: "accessibility_reading_volume \(vol)")
        }
        return label
    }

    private var cloudAccessibilityLabel: String {
        var label = String(localized: "sync_cloud") + ", "
        label += String(localized: "accessibility_volumes_count \(conflict.cloudVolumesOwned.count)")
        if let vol = conflict.cloudReadingVolume {
            label += ", " + String(localized: "accessibility_reading_volume \(vol)")
        }
        return label
    }

    private func resolveKeepLocal() {
        isResolving = true
        Task {
            await cloudVM.resolveConflictKeepLocal(conflict)
            isResolving = false
        }
    }

    private func resolveUseCloud() {
        isResolving = true
        Task {
            await cloudVM.resolveConflictUseCloud(conflict)
            isResolving = false
        }
    }
}

// MARK: - Preview

#Preview(traits: .sampleData) {
    SyncConflictView()
}
