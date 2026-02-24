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
            Section {
                Label("nav_home", systemImage: "house.fill")
                    .tag(NavigationItem.home)

                HStack {
                    Label("nav_collection", systemImage: "folder.fill")
                    Spacer()
                    if authVM.isAuthenticated {
                        Image(systemName: "cloud.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                .tag(NavigationItem.collection)

                Label("nav_profile", systemImage: "person.fill")
                    .tag(NavigationItem.profile)

                Label("nav_search", systemImage: "magnifyingglass")
                    .tag(NavigationItem.search)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("app_name")
    }
}

#Preview {
    @Previewable @State var selection: NavigationItem? = .home
    MacSidebarView(selection: $selection)
        .environment(AuthViewModel())
}
