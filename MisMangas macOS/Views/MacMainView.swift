//
//  MacMainView.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

enum NavigationItem: Hashable {
    case home
    case search
    case collection
    case profile
}

struct MacMainView: View {
    @Environment(AuthViewModel.self) private var authVM

    @State private var selectedSection: NavigationItem? = .home
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
            // CONTENIDO (Columna 2)
            Group {
                switch selectedSection {
                case .home:
                    MacHomeView(selection: $selectedManga)
                case .search:
                    MacSearchView(selection: $selectedManga)
                case .collection:
                    MacCollectionView(selection: $selectedManga)
                case .profile:
                    MacProfileView()
                case .none:
                    ContentUnavailableView(
                        "empty_select_section",
                        systemImage: "sidebar.left"
                    )
                }
            }
            .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 500)
            .onChange(of: selectedSection) { oldValue, newValue in
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
        .sheet(isPresented: $showLogin) {
            MacLoginView()
        }
        .preferredColorScheme(colorScheme)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToSection)) { notification in
            if let section = notification.object as? NavigationItem {
                selectedSection = section
            }
        }
    }

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
}

#Preview {
    MacMainView()
        .environment(AuthViewModel())
        .environment(CloudCollectionViewModel(authVM: AuthViewModel()))
}
