//
//  ProfileView.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true
    @State private var showLoginSheet = false
    @State private var showLogoutAlert = false
    @State private var showSettings = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: UIImage?

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Header del Perfil
                Section {
                    HStack(spacing: 16) {
                        // Avatar
                        if let image = profileImage {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.blue, lineWidth: 2)
                                    )
                                    .accessibilityHidden(true)
                            }
                        } else {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 72, height: 72)
                                    .foregroundStyle(.secondary)
                                    .accessibilityHidden(true)
                            }
                            .disabled(!authVM.isAuthenticated)
                        }

                        // Info del usuario
                        VStack(alignment: .leading, spacing: 4) {
                            if authVM.isAuthenticated {
                                Text(authVM.userEmail ?? "Usuario")
                                    .font(.headline)
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.caption)
                                    Text("profile_connected")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                Text("profile_not_connected")
                                    .font(.headline)
                                Text("profile_login_prompt")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(authVM.isAuthenticated
                        ? String(localized: "accessibility_user_connected") + ", " + (authVM.userEmail ?? "")
                        : String(localized: "accessibility_user_not_connected"))
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                await authVM.saveProfileImage(image)
                                profileImage = image
                            }
                        }
                    }
                    .onAppear {
                        profileImage = authVM.userProfileImage
                    }
                }

                // MARK: - Cuenta
                Section {
                    if authVM.isAuthenticated {
                        Button(role: .destructive) {
                            showLogoutAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundStyle(.red)
                                    .accessibilityHidden(true)
                                Text("action_logout")
                                    .foregroundStyle(.red)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityHint(String(localized: "accessibility_logout_hint"))
                    } else {
                        Button {
                            showLoginSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.key.fill")
                                    .foregroundStyle(.blue)
                                    .accessibilityHidden(true)
                                Text("action_login")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityHint(String(localized: "accessibility_login_hint"))
                    }
                } header: {
                    Text("profile_account")
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                } footer: {
                    Text(authVM.isAuthenticated ? "profile_storage_cloud" : "profile_storage_local")
                }

                // MARK: - Colección
                Section {
                    HStack {
                        Image(systemName: "cloud.fill")
                            .foregroundStyle(authVM.isAuthenticated ? .blue : .secondary)
                            .accessibilityHidden(true)
                        Text("profile_cloud_collection")
                        Spacer()
                        Text(authVM.isAuthenticated ? String(localized: "profile_session_active") : "-")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(String(localized: "accessibility_cloud_storage") + ": " + (authVM.isAuthenticated ? String(localized: "profile_session_active") : String(localized: "accessibility_inactive")))

                    HStack {
                        Image(systemName: "internaldrive.fill")
                            .foregroundStyle(.green)
                            .accessibilityHidden(true)
                        Text("profile_local_collection")
                        Spacer()
                        Text("profile_session_active")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(String(localized: "accessibility_local_storage") + ": " + String(localized: "profile_session_active"))
                } header: {
                    Text("profile_storage")
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                }
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
#Preview("No autenticado") {
    @Previewable @State var authVM = AuthViewModel()
    ProfileView()
        .environment(authVM)
}

#Preview("Autenticado") {
    @Previewable @State var authVM = AuthViewModel()
    ProfileView()
        .environment(authVM)
        .onAppear {
            authVM.isAuthenticated = true
            authVM.userEmail = "test@example.com"
        }
}
