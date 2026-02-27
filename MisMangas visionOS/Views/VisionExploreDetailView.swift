//
//  VisionExploreDetailView.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 18/02/26.
//

import SwiftUI
import SwiftData

struct VisionExploreDetailView: View {
    let manga: Manga

    @Environment(AuthViewModel.self) var authVM
    @Environment(CloudCollectionViewModel.self) var cloudVM
    @Environment(TranslationService.self) var translationService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query var localCollection: [UserCollection]

    @State var showAddSheet = false
    @State var isInCollection = false
    @State var coverVM = MangaCoverVM()
    @State private var detailVM: MangaDetailViewModel?
    @State private var navigateToManga: Manga?

    // Translation
    @State var translatedSynopsis: String?
    @State var isTranslating = false
    @State var showOriginal = false
    @State var showFullSynopsis = false

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                HStack(alignment: .top, spacing: 60) {
                    coverSection
                    infoSection
                }

                // Related Mangas Section
                if let vm = detailVM {
                    VisionRelatedMangasSection(
                        relatedMangas: vm.relatedMangas,
                        relatedMangaDetails: vm.relatedMangaDetails,
                        recommendations: vm.recommendations,
                        isLoading: vm.isLoadingRelated,
                        onMangaTap: { mangaId in
                            Task {
                                await vm.loadAndNavigateToManga(id: mangaId)
                            }
                        }
                    )
                }
            }
            .padding(60)
        }
        .navigationTitle(manga.title)
        .navigationDestination(for: Manga.self) { manga in
            VisionExploreDetailView(manga: manga)
        }
        .navigationDestination(item: $navigateToManga) { manga in
            VisionExploreDetailView(manga: manga)
        }
        .sheet(isPresented: $showAddSheet) {
            VisionAddToCollectionSheet(manga: manga) {
                isInCollection = true
            }
        }
        .task {
            checkIfInCollection()
            detailVM = MangaDetailViewModel(manga: manga, translationService: translationService)
            await detailVM?.loadAllData()
        }
        .onChange(of: detailVM?.selectedRelatedManga) { _, newManga in
            if let manga = newManga {
                navigateToManga = manga
            }
        }
    }
}

#Preview {
    NavigationStack {
        VisionExploreDetailView(manga: .test)
    }
    .environment(AuthViewModel())
    .environment(CloudCollectionViewModel(authVM: AuthViewModel()))
    .environment(TranslationService())
}
