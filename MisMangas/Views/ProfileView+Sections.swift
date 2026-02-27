//
//  ProfileView+Sections.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI
import PhotosUI

// MARK: - Header Section

struct ProfileHeaderSection: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: UIImage?

    var body: some View {
        let currentImage = profileImage

        Section {
            HStack(spacing: 16) {
                // Avatar
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Group {
                        if let image = currentImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 72, height: 72)
                    .accessibilityHidden(true)
                }
                .disabled(!authVM.isAuthenticated)

                // User Info
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
    }
}

// MARK: - Account Section

struct ProfileAccountSection: View {
    @Environment(AuthViewModel.self) private var authVM
    @Binding var showLoginSheet: Bool
    @Binding var showLogoutAlert: Bool

    var body: some View {
        Section {
            if authVM.isAuthenticated {
                logoutButton
            } else {
                loginButton
            }
        } header: {
            Text("profile_account")
                .accessibilityHeader(.h2)
        } footer: {
            Text(authVM.isAuthenticated ? "profile_storage_cloud" : "profile_storage_local")
        }
    }

    private var logoutButton: some View {
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
    }

    private var loginButton: some View {
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
}

// MARK: - Storage Section

struct ProfileStorageSection: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        Section {
            cloudRow
            localRow
        } header: {
            Text("profile_storage")
                .accessibilityHeader(.h2)
        }
    }

    private var cloudRow: some View {
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
    }

    private var localRow: some View {
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
    }
}
