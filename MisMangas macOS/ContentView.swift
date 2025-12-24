//
//  ContentView.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("app_name")
                .font(.largeTitle.bold())

            Text("mac_app_ready")
                .font(.title2)
                .foregroundStyle(.secondary)

            Divider()
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 12) {
                Label("mac_feature_sidebar", systemImage: "sidebar.left")
                Label("mac_feature_menus", systemImage: "menubar.rectangle")
                Label("mac_feature_shortcuts", systemImage: "command")
                Label("mac_feature_windows", systemImage: "macwindow.on.rectangle")
            }
            .font(.headline)
            .foregroundStyle(.green)
        }
        .frame(minWidth: 500, minHeight: 400)
        .padding(40)
    }
}

#Preview {
    ContentView()
}
