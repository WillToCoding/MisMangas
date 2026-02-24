//
//  VisionExploreDetailView.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 18/02/26.
//

import SwiftUI

struct VisionExploreDetailView: View {
    let manga: Manga

    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.dismiss) private var dismiss

    @State private var showAddSheet = false
    @State private var isInCollection = false

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 60) {
                // Portada grande
                AsyncImage(url: manga.coverURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.gray.opacity(0.3))
                        .overlay {
                            ProgressView()
                        }
                }
                .frame(width: 350, height: 525)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 30)

                // Información
                VStack(alignment: .leading, spacing: 24) {
                    // Título
                    Text(manga.title)
                        .font(.system(size: 42, weight: .bold))

                    if let titleJapanese = manga.titleJapanese {
                        Text(titleJapanese)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }

                    // Stats
                    HStack(spacing: 40) {
                        StatBadge(title: "detail_score", value: manga.score.formatted(.number.precision(.fractionLength(2))), icon: "star.fill", color: .yellow)

                        if let volumes = manga.volumes {
                            StatBadge(title: "detail_volumes", value: "\(volumes)", icon: "book.closed", color: .blue)
                        }

                        if let chapters = manga.chapters {
                            StatBadge(title: "detail_chapters", value: "\(chapters)", icon: "doc.text", color: .green)
                        }

                        StatBadge(title: "detail_status", value: manga.status.capitalized, icon: "clock", color: .orange)
                    }

                    Divider()

                    // Sinopsis
                    if let synopsis = manga.sypnosis, !synopsis.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("detail_synopsis")
                                .font(.title2.bold())

                            Text(synopsis)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .lineLimit(8)
                        }
                    }

                    Divider()

                    // Géneros
                    if !manga.genres.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("detail_genres")
                                .font(.title3.bold())

                            HStack(spacing: 10) {
                                ForEach(manga.genres.prefix(5)) { genre in
                                    Text(genre.genre)
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(.blue.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    Spacer()

                    // Botón de añadir a colección
                    if authVM.isAuthenticated {
                        if isInCollection {
                            Label("collection_already_added", systemImage: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.green)
                        } else {
                            Button {
                                showAddSheet = true
                            } label: {
                                Label("action_add_collection", systemImage: "plus.circle.fill")
                                    .font(.title3)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                    } else {
                        Text("collection_login_required")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: 600, alignment: .leading)
            }
            .padding(60)
        }
        .navigationTitle(manga.title)
        .sheet(isPresented: $showAddSheet) {
            VisionAddToCollectionSheet(manga: manga) {
                isInCollection = true
            }
        }
        .task {
            checkIfInCollection()
        }
    }

    private func checkIfInCollection() {
        isInCollection = cloudVM.cloudCollection.contains { $0.manga.id == manga.id }
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 80)
    }
}

// MARK: - Add to Collection Sheet
struct VisionAddToCollectionSheet: View {
    let manga: Manga
    let onAdded: () -> Void

    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.dismiss) private var dismiss

    @State private var volumesOwned: [Int] = []
    @State private var currentVolume: Int = 1
    @State private var completeCollection = false
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("edit_progress_section") {
                    Stepper("vol_current \(currentVolume)", value: $currentVolume, in: 1...(manga.volumes ?? 100))
                }

                Section {
                    Toggle("collection_complete", isOn: $completeCollection)
                }

                if let total = manga.volumes {
                    Section("collection_volumes_owned") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 10) {
                            ForEach(1...total, id: \.self) { vol in
                                Button {
                                    if volumesOwned.contains(vol) {
                                        volumesOwned.removeAll { $0 == vol }
                                    } else {
                                        volumesOwned.append(vol)
                                    }
                                } label: {
                                    Text("\(vol)")
                                        .frame(width: 44, height: 44)
                                        .background(volumesOwned.contains(vol) ? Color.accentColor : Color.gray.opacity(0.3))
                                        .foregroundStyle(volumesOwned.contains(vol) ? .white : .primary)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle(manga.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action_cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await addToCollection()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("action_add")
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }

    private func addToCollection() async {
        isSaving = true

        do {
            try await cloudVM.addToCollection(
                manga: manga,
                volumesOwned: volumesOwned,
                readingVolume: currentVolume,
                completeCollection: completeCollection
            )
            onAdded()
            dismiss()
        } catch {
            print("[VISION] Error adding to collection: \(error)")
        }

        isSaving = false
    }
}

#Preview {
    NavigationStack {
        VisionExploreDetailView(manga: .test)
    }
    .environment(AuthViewModel())
    .environment(CloudCollectionViewModel(authVM: AuthViewModel()))
}
