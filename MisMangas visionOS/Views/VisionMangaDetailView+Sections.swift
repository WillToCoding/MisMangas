//
//  VisionMangaDetailView+Sections.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 26/02/26.
//

import SwiftUI

// MARK: - Cover Section

extension VisionMangaDetailView {
    var coverSection: some View {
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
                        } else {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.gray)
                        }
                    }
            }
        }
        .frame(width: 400, height: 600)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 30)
    }
}

// MARK: - Info Section

extension VisionMangaDetailView {
    var infoSection: some View {
        VStack(alignment: .leading, spacing: 30) {
            titleSection
            statsSection
            genresSection
            synopsisSection

            Divider()

            volumesOwnedSection
            readingVolumeSection

            Divider()

            readingStatusSection

            Divider()

            actionButtons
        }
        .frame(maxWidth: 600)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.collectionTitle)
                .font(.system(size: 48, weight: .bold))

            if let titleJapanese = item.collectionTitleJapanese {
                Text(titleJapanese)
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 30) {
            Label(item.collectionScore.formatted(.number.precision(.fractionLength(2))), systemImage: "star.fill")
                .foregroundStyle(.yellow)
                .font(.title3.bold())

            if let volumes = item.collectionTotalVolumes {
                Label("\(volumes) vol.", systemImage: "book.closed")
                    .foregroundStyle(.blue)
                    .font(.title3)
            }

            if let chapters = item.collectionTotalChapters {
                Label("\(chapters) cap.", systemImage: "doc.text")
                    .foregroundStyle(.green)
                    .font(.title3)
            }

            Label(item.collectionStatus.capitalized, systemImage: item.collectionStatus == "finished" ? "checkmark.circle.fill" : "clock")
                .foregroundStyle(item.collectionStatus == "finished" ? .green : .orange)
                .font(.title3)
        }
    }

    private var genresSection: some View {
        Group {
            if !item.collectionGenres.isEmpty {
                HStack(spacing: 10) {
                    ForEach(item.collectionGenres.prefix(5), id: \.self) { genre in
                        Text(genre)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.blue.opacity(0.2), in: Capsule())
                    }
                }
            }
        }
    }

    private var synopsisSection: some View {
        Group {
            if let synopsis = item.collectionSynopsis, !synopsis.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("detail_synopsis")
                            .font(.title3.bold())
                        Spacer()
                        translationButton(synopsis: synopsis)
                    }
                    Text(showOriginal ? synopsis : (translatedSynopsis ?? synopsis))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(showFullSynopsis ? nil : 4)

                    Button {
                        withAnimation {
                            showFullSynopsis.toggle()
                        }
                    } label: {
                        Text(showFullSynopsis ? "home_show_less" : "home_show_more")
                            .font(.subheadline.bold())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }
            }
        }
    }
}
