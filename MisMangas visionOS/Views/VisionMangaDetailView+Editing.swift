//
//  VisionMangaDetailView+Editing.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 26/02/26.
//

import SwiftUI

// MARK: - Volumes Owned Section

extension VisionMangaDetailView {
    var volumesOwnedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("edit_volumes_owned")
                    .font(.title2.bold())
                Spacer()
                if ownedVolumes == totalVolumes {
                    Label("collection_complete", systemImage: "checkmark.seal.fill")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
            }

            HStack(spacing: 20) {
                Button {
                    if ownedVolumes > 0 {
                        ownedVolumes -= 1
                        if currentVolume > max(1, ownedVolumes) {
                            currentVolume = max(1, ownedVolumes)
                        }
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundStyle(ownedVolumes > 0 ? .orange : .gray)
                }
                .disabled(ownedVolumes <= 0)

                VStack(spacing: 4) {
                    Text("\(ownedVolumes)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                        .contentTransition(.numericText())
                    Text("de \(totalVolumes)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 100)

                Button {
                    if ownedVolumes < totalVolumes {
                        ownedVolumes += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundStyle(ownedVolumes < totalVolumes ? .orange : .gray)
                }
                .disabled(ownedVolumes >= totalVolumes)
            }

            ProgressView(value: Double(ownedVolumes), total: Double(totalVolumes))
                .tint(.orange)
                .frame(maxWidth: 400)
        }
        .padding(20)
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Reading Volume Section

extension VisionMangaDetailView {
    var readingVolumeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("edit_reading_volume")
                    .font(.title2.bold())
                Spacer()
                let progress = Int((Double(currentVolume) / Double(totalVolumes)) * 100)
                Text("\(progress)%")
                    .font(.title3.bold())
                    .foregroundStyle(progress == 100 ? .green : .blue)
            }

            HStack(spacing: 20) {
                Button {
                    if currentVolume > 1 {
                        currentVolume -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundStyle(currentVolume > 1 ? .blue : .gray)
                }
                .disabled(currentVolume <= 1)

                VStack(spacing: 4) {
                    Text("Vol. \(currentVolume)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                        .contentTransition(.numericText())
                    Text("de \(totalVolumes)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 150)

                Button {
                    let maxReading = ownedVolumes > 0 ? ownedVolumes : totalVolumes
                    if currentVolume < maxReading {
                        currentVolume += 1
                    }
                } label: {
                    let maxReading = ownedVolumes > 0 ? ownedVolumes : totalVolumes
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundStyle(currentVolume < maxReading ? .blue : .gray)
                }
                .disabled(currentVolume >= (ownedVolumes > 0 ? ownedVolumes : totalVolumes))
            }

            ProgressView(value: Double(currentVolume), total: Double(totalVolumes))
                .tint(currentVolume == totalVolumes ? .green : .blue)
                .frame(maxWidth: 400)
        }
        .padding(20)
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Reading Status Section

extension VisionMangaDetailView {
    var readingStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("edit_reading_status")
                .font(.title2.bold())

            HStack(spacing: 16) {
                Button {
                    isCompleted = false
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "book.fill")
                        Text("reading_status_reading")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        !isCompleted ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(!isCompleted ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    isCompleted = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("reading_status_completed")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        isCompleted ? Color.green.opacity(0.3) : Color.gray.opacity(0.2),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isCompleted ? Color.green : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Action Buttons

extension VisionMangaDetailView {
    var actionButtons: some View {
        HStack(spacing: 20) {
            Button {
                Task { await saveProgress() }
            } label: {
                if isSaving {
                    ProgressView()
                } else if showSuccess {
                    Label("action_save", systemImage: "checkmark.circle.fill")
                } else {
                    Label("action_save", systemImage: "square.and.arrow.up")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isSaving || !hasChanges)
            .tint(showSuccess ? .green : .accentColor)

            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                if isDeleting {
                    ProgressView()
                } else {
                    Label("action_delete", systemImage: "trash")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(isDeleting)
        }
    }
}
