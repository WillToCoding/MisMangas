//
//  MacMainView.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

enum NavigationItem: Hashable {
    case explore
    case collection
    case bestMangas
}

struct MacMainView: View {
    @Environment(AuthViewModel.self) private var authVM

    // ViewModels separados para cada sección
    @State private var exploreVM = MangaViewModel()
    @State private var bestMangasVM = MangaViewModel()
    @State private var filterVM = FilterViewModel()

    @State private var selectedSection: NavigationItem? = .explore
    @State private var selectedManga: Manga?
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var showLogin = false

    @AppStorage("appearanceMode") private var appearanceMode = "auto"

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // SIDEBAR (Columna 1)
            MacSidebarView(selection: $selectedSection)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)

        } content: {
            // LISTA (Columna 2)
            Group {
                switch selectedSection {
                case .explore:
                    MacMangaListView(selection: $selectedManga)
                        .environment(exploreVM)
                        .environment(filterVM)
                case .collection:
                    MacCollectionView(selection: $selectedManga)
                case .bestMangas:
                    MacBestMangasView(selection: $selectedManga)
                        .environment(bestMangasVM)
                case .none:
                    ContentUnavailableView(
                        "empty_select_section",
                        systemImage: "sidebar.left"
                    )
                }
            }
            .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 500)
            .onChange(of: selectedSection) { oldValue, newValue in
                // Resetear selección al cambiar de sección
                selectedManga = nil
            }

        } detail: {
            // DETALLE (Columna 3)
            if let manga = selectedManga {
                MacMangaDetailView(manga: manga)
            } else {
                ContentUnavailableView(
                    "empty_select_manga",
                    systemImage: "book.closed",
                    description: Text("empty_select_manga_description")
                )
            }
        }
        .toolbar {
            ToolbarItem {
                if authVM.isAuthenticated {
                    Menu {
                        Text(authVM.userEmail ?? "")
                        Divider()
                        Button("action_logout", role: .destructive) {
                            authVM.logout()
                        }
                    } label: {
                        Label("profile_account", systemImage: "person.circle.fill")
                    }
                } else {
                    Button("action_login") {
                        showLogin = true
                    }
                }
            }
        }
        .sheet(isPresented: $showLogin) {
            MacLoginView()
        }
        .preferredColorScheme(colorScheme)
    }

    // Computed property para el color scheme
    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "light":
            return .light
        case "dark":
            return .dark
        default: // "auto"
            return nil
        }
    }
}

// MARK: - Best Mangas View
struct MacBestMangasView: View {
    @Binding var selection: Manga?
    @Environment(MangaViewModel.self) private var mangaVM

    var body: some View {
        VStack(spacing: 0) {
            // Lista
            if mangaVM.isLoading {
                ProgressView("loading_mangas")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = mangaVM.errorMessage {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                List(mangaVM.mangas, selection: $selection) { manga in
                    MacMangaRow(manga: manga)
                        .tag(manga)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("best_mangas_title")
        .task {
            if mangaVM.mangas.isEmpty {
                await mangaVM.fetchBestMangas()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshContent)) { _ in
            Task {
                await mangaVM.fetchBestMangas()
            }
        }
    }
}

#Preview {
    MacMainView()
        .environment(AuthViewModel())
        .environment(CloudCollectionViewModel(authVM: AuthViewModel()))
}
