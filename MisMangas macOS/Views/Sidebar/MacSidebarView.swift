//
//  MacSidebarView.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct MacSidebarView: View {
    @Binding var selection: NavigationItem?
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        List(selection: $selection) {
            Section("nav_explore") {
                Label("nav_explore", systemImage: "books.vertical")
                    .tag(NavigationItem.explore)

                Label("best_mangas_title", systemImage: "star.fill")
                    .tag(NavigationItem.bestMangas)
            }

            Section("mac_categories") {
                HStack {
                    Label("nav_collection", systemImage: "folder.fill")
                    Spacer()
                    Text(authVM.isAuthenticated ? "collection_cloud" : "collection_local")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .tag(NavigationItem.collection)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("app_name")
    }
}

#Preview {
    MacSidebarView(selection: .constant(.explore))
        .environment(AuthViewModel())
}
