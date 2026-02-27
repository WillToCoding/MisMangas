//
//  TVMangaDetailView+Sections.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 25/2/26.
//

import SwiftUI

// MARK: - UI Sections

extension TVMangaDetailView {

    // MARK: - Cover Section

    var coverSection: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image = coverVM.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .overlay {
                            if coverVM.isLoading {
                                ProgressView()
                                    .scaleEffect(1.5)
                            } else {
                                Image(systemName: "book.closed")
                                    .font(.system(size: 80))
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
            }
            .frame(width: 400, height: 600)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.4), radius: 30, y: 15)

            if item.collectionIsComplete {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(.green.gradient, in: Circle())
                    .shadow(radius: 10)
                    .padding(20)
            }
        }
    }

    // MARK: - Info Section

    var infoSection: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Title
            VStack(alignment: .leading, spacing: 12) {
                Text(item.collectionTitle)
                    .font(.system(size: 56, weight: .bold))
                    .lineLimit(3)

                if let titleJapanese = item.collectionTitleJapanese {
                    Text(titleJapanese)
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                }
            }

            // Stats - mismo estilo que Home
            HStack(spacing: 40) {
                Label(item.collectionScore.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
                    .foregroundStyle(.yellow)
                if let volumes = item.collectionTotalVolumes {
                    Label("\(volumes) vols", systemImage: "book.closed")
                }
                if let chapters = item.collectionTotalChapters {
                    Label("\(chapters) caps", systemImage: "doc.text")
                }
                Label(item.collectionStatus.capitalized, systemImage: "clock")
            }
            .font(.system(size: 28, weight: .medium))

            // Géneros
            if !item.collectionGenres.isEmpty {
                HStack(spacing: 12) {
                    ForEach(item.collectionGenres.prefix(6), id: \.self) { genre in
                        Text(genre)
                            .font(.system(size: 22))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.blue.opacity(0.2), in: Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: 1000, alignment: .leading)
    }

    // MARK: - Synopsis Section

    var synopsisSection: some View {
        Group {
            if let synopsis = item.collectionSynopsis {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("detail_synopsis")
                            .font(.system(size: 36, weight: .bold))
                        Spacer()
                        translationButton
                    }
                    Text(showOriginal ? synopsis : (translatedSynopsis ?? synopsis))
                        .font(.system(size: 26))
                        .foregroundStyle(.secondary)
                        .lineLimit(showFullSynopsis ? nil : 4)
                        .lineSpacing(8)

                    Button {
                        withAnimation {
                            showFullSynopsis.toggle()
                        }
                    } label: {
                        Text(showFullSynopsis ? "home_show_less" : "home_show_more")
                            .font(.system(size: 24, weight: .semibold))
                    }
                }
                .frame(maxWidth: 1000, alignment: .leading)
            }
        }
    }

    // MARK: - Volumes Owned Section

    var volumesOwnedSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label("edit_volumes_owned", systemImage: "books.vertical.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.orange)

                Spacer()

                if Int(ownedVolumes) == totalVolumes {
                    Label("collection_complete", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.green)
                }
            }

            HStack(spacing: 40) {
                Button {
                    if ownedVolumes > 0 {
                        ownedVolumes -= 1
                        if currentVolume > max(1, ownedVolumes) {
                            currentVolume = max(1, ownedVolumes)
                        }
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(ownedVolumes > 0 ? .orange : .gray)
                }
                .disabled(ownedVolumes <= 0)

                VStack(spacing: 4) {
                    Text("\(Int(ownedVolumes))")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                        .contentTransition(.numericText())
                        .animation(.spring, value: ownedVolumes)
                    if let total = item.collectionTotalVolumes {
                        Text("de \(total)")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(minWidth: 150)

                Button {
                    if ownedVolumes < Double(totalVolumes) {
                        ownedVolumes += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(ownedVolumes < Double(totalVolumes) ? .orange : .gray)
                }
                .disabled(ownedVolumes >= Double(totalVolumes))
            }

            ProgressView(value: ownedVolumes, total: Double(totalVolumes))
                .tint(.orange)
                .scaleEffect(y: 2)
        }
        .padding(30)
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Reading Volume Section

    var readingVolumeSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label("edit_reading_volume", systemImage: "bookmark.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.blue)

                Spacer()

                Text("\(progressPercentage)%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(progressPercentage == 100 ? .green : .blue)
                    .contentTransition(.numericText())
            }

            HStack(spacing: 40) {
                Button {
                    if currentVolume > 1 {
                        currentVolume -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(currentVolume > 1 ? .blue : .gray)
                }
                .disabled(currentVolume <= 1)

                VStack(spacing: 4) {
                    Text("Vol. \(Int(currentVolume))")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                        .contentTransition(.numericText())
                    if let total = item.collectionTotalVolumes {
                        Text("de \(total)")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(minWidth: 250)

                Button {
                    let maxReading = ownedVolumes > 0 ? ownedVolumes : Double(totalVolumes)
                    if currentVolume < maxReading {
                        currentVolume += 1
                    }
                } label: {
                    let maxReading = ownedVolumes > 0 ? ownedVolumes : Double(totalVolumes)
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(currentVolume < maxReading ? .blue : .gray)
                }
                .disabled(currentVolume >= (ownedVolumes > 0 ? ownedVolumes : Double(totalVolumes)))
            }

            ProgressView(value: currentVolume, total: Double(totalVolumes))
                .tint(progressPercentage == 100 ? .green : .blue)
                .scaleEffect(y: 2)
        }
        .padding(30)
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Reading Status Section

    var readingStatusSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("edit_reading_status", systemImage: "bookmark.circle.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.green)

            HStack(spacing: 40) {
                Button {
                    isCompleted = false
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 32))
                        Text("reading_status_reading")
                            .font(.system(size: 28, weight: .semibold))
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(
                        !isCompleted ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(!isCompleted ? Color.blue : Color.clear, lineWidth: 3)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    isCompleted = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                        Text("reading_status_completed")
                            .font(.system(size: 28, weight: .semibold))
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(
                        isCompleted ? Color.green.opacity(0.3) : Color.gray.opacity(0.2),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isCompleted ? Color.green : Color.clear, lineWidth: 3)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(30)
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Save Button Section

    var saveButtonSection: some View {
        VStack(spacing: 20) {
            if showSavedConfirmation {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("collection_updated_success")
                }
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.green)
                .transition(.opacity)
            }

            Button {
                Task {
                    await saveProgress()
                }
            } label: {
                if isSaving {
                    ProgressView()
                        .frame(width: 300)
                } else {
                    Label("action_save", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 32, weight: .semibold))
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving || !hasChanges)
        }
        .frame(maxWidth: .infinity)
        .animation(.spring, value: showSavedConfirmation)
    }

    // MARK: - Delete Button Section

    var deleteButtonSection: some View {
        VStack(spacing: 20) {
            Button {
                showDeleteAlert = true
            } label: {
                if isDeleting {
                    ProgressView()
                        .frame(width: 300)
                } else {
                    Label("action_delete", systemImage: "trash")
                        .font(.system(size: 28, weight: .semibold))
                }
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .disabled(isDeleting)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Translation Button

    var translationButton: some View {
        Group {
            if translationService.isConfigured {
                if isTranslating {
                    ProgressView()
                } else if translatedSynopsis != nil {
                    Button {
                        showOriginal.toggle()
                    } label: {
                        Label(
                            showOriginal ? "translation_show_translated" : "translation_show_original",
                            systemImage: "globe"
                        )
                        .font(.system(size: 24))
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        Task { await translateSynopsis() }
                    } label: {
                        Label("translation_translate", systemImage: "globe")
                            .font(.system(size: 24))
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}
