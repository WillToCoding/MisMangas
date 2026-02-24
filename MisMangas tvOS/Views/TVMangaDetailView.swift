//
//  TVMangaDetailView.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct TVMangaDetailView: View {
    let item: UserMangaCollection
    let onSave: () -> Void

    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.dismiss) private var dismiss

    @State private var coverVM = MangaCoverVM()
    @State private var currentVolume: Double
    @State private var ownedVolumes: Double
    @State private var isSaving = false
    @State private var showSavedConfirmation = false

    init(item: UserMangaCollection, onSave: @escaping () -> Void = {}) {
        self.item = item
        self.onSave = onSave
        _currentVolume = State(initialValue: Double(item.readingVolume ?? 1))
        _ownedVolumes = State(initialValue: Double(item.volumesOwned.count))
    }

    private var totalVolumes: Int {
        item.manga.volumes ?? 50
    }

    private var progressPercentage: Int {
        Int((currentVolume / Double(totalVolumes)) * 100)
    }

    private var hasChanges: Bool {
        Int(currentVolume) != item.readingVolume || Int(ownedVolumes) != item.volumesOwned.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 50) {
                // MARK: - Back Button (top)
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Label("action_back", systemImage: "chevron.left")
                            .font(.system(size: 32, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                }
                .focusSection()

                // MARK: - Cover + Info (no buttons, no focusSection)
                HStack(alignment: .top, spacing: 80) {
                    // Cover
                    ZStack(alignment: .topTrailing) {
                        Group {
                            if let image = coverVM.image {
                                #if os(tvOS)
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                #endif
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

                        if item.completeCollection {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.white)
                                .padding(16)
                                .background(.green.gradient, in: Circle())
                                .shadow(radius: 10)
                                .padding(20)
                        }
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 30) {
                        // Title
                        VStack(alignment: .leading, spacing: 12) {
                            Text(item.manga.title)
                                .font(.system(size: 56, weight: .bold))
                                .lineLimit(3)

                            if let titleJapanese = item.manga.titleJapanese {
                                Text(titleJapanese)
                                    .font(.system(size: 28))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Stats
                        HStack(spacing: 60) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("detail_score")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 10) {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                        .font(.system(size: 36))
                                    Text(item.manga.score.formatted(.number.precision(.fractionLength(2))))
                                        .font(.system(size: 48, weight: .bold))
                                }
                            }

                            if let volumes = item.manga.volumes {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("detail_volumes")
                                        .font(.system(size: 24))
                                        .foregroundStyle(.secondary)
                                    Text("\(volumes)")
                                        .font(.system(size: 48, weight: .bold))
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("detail_status")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(item.manga.status == "finished" ? .green : .blue)
                                        .frame(width: 16, height: 16)
                                    Text(item.manga.status == "finished" ? "status_finished" : "status_publishing")
                                        .font(.system(size: 32, weight: .semibold))
                                        .foregroundStyle(item.manga.status == "finished" ? .green : .blue)
                                }
                            }
                        }

                        // Synopsis
                        if let synopsis = item.manga.sypnosis {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("detail_synopsis")
                                    .font(.system(size: 36, weight: .bold))
                                Text(synopsis)
                                    .font(.system(size: 26))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(4)
                                    .lineSpacing(8)
                            }
                        }
                    }
                    .frame(maxWidth: 1000, alignment: .leading)
                }

                Divider()
                    .background(.secondary)

                // MARK: - Volumes Owned Controls
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
                            if let total = item.manga.volumes {
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
                .focusSection()

                // MARK: - Reading Volume Controls
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
                            if let total = item.manga.volumes {
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
                .focusSection()

                // MARK: - Save Button (bottom)
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
                .focusSection()

                Spacer(minLength: 100)
            }
            .padding(80)
        }
        .navigationTitle(item.manga.title)
        .task {
            coverVM.getImage(url: item.manga.coverURL)
        }
        .onExitCommand {
            dismiss()
        }
    }

    // MARK: - Save Progress
    private func saveProgress() async {
        isSaving = true

        let ownedCount = Int(ownedVolumes)
        let newVolumesOwned = ownedCount > 0 ? Array(1...ownedCount) : []
        let isComplete = ownedCount == totalVolumes

        do {
            try await cloudVM.addToCollection(
                manga: item.manga,
                volumesOwned: newVolumesOwned,
                readingVolume: Int(currentVolume),
                completeCollection: isComplete
            )

            showSavedConfirmation = true
            try? await Task.sleep(for: .seconds(1.5))
            showSavedConfirmation = false

            onSave()

            try? await Task.sleep(for: .milliseconds(200))
            dismiss()
        } catch {
            print("[TV] Error guardando progreso: \(error)")
        }

        isSaving = false
    }
}

#Preview {
    let authVM = AuthViewModel()
    return NavigationStack {
        TVMangaDetailView(
            item: UserMangaCollection(
                id: "1",
                manga: .test,
                completeCollection: false,
                volumesOwned: [1, 2, 3],
                readingVolume: 2
            )
        )
    }
    .environment(authVM)
    .environment(CloudCollectionViewModel(authVM: authVM))
}
