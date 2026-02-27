//
//  ProfileView.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var showLoginSheet = false
    @State private var showLogoutAlert = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            List {
                ProfileHeaderSection()
                ProfileAccountSection(
                    showLoginSheet: $showLoginSheet,
                    showLogoutAlert: $showLogoutAlert
                )
                ProfileStorageSection()
            }
            .navigationTitle("nav_profile")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel(String(localized: "settings_title"))
                }
            }
            .sheet(isPresented: $showLoginSheet) {
                LoginView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("profile_logout_title", isPresented: $showLogoutAlert) {
                Button("action_cancel", role: .cancel) { }
                Button("action_logout", role: .destructive) {
                    authVM.logout()
                }
            } message: {
                Text("profile_logout_message")
            }
        }
    }
}

// MARK: - Preview

#Preview(traits: .sampleData) {
    ProfileView()
}
