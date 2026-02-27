//
//  MacProfileView.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 22/2/26.
//

import SwiftUI
import PhotosUI

struct MacProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM

    @State private var showLoginSheet = false
    @State private var showRegisterSheet = false
    @State private var showLogoutAlert = false
    @State private var showSettings = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: NSImage?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader
                    .padding(.top, 20)

                accountSection
                storageSection

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 40)
        }
        .frame(minWidth: 400)
        .navigationTitle("nav_profile")
        .toolbar { toolbarContent }
        .sheet(isPresented: $showLoginSheet) {
            MacLoginView()
                .frame(minWidth: 400, minHeight: 300)
        }
        .sheet(isPresented: $showRegisterSheet) {
            MacRegisterView()
                .frame(minWidth: 450, minHeight: 500)
        }
        .sheet(isPresented: $showSettings) {
            MacSettingsView()
                .frame(minWidth: 500, minHeight: 400)
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

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            avatarPicker

            if authVM.isAuthenticated {
                Text(authVM.userEmail ?? "Usuario")
                    .font(.title2.bold())

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("profile_connected")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            } else {
                Text("profile_not_connected")
                    .font(.title2.bold())

                Text("profile_login_prompt")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .task(id: selectedPhotoItem) {
            guard let newItem = selectedPhotoItem,
                  let data = try? await newItem.loadTransferable(type: Data.self),
                  let image = NSImage(data: data) else { return }
            await authVM.saveProfileImage(image)
            profileImage = image
        }
        .onAppear {
            profileImage = authVM.userProfileImage
        }
        .onChange(of: authVM.isAuthenticated) { _, isAuthenticated in
            profileImage = isAuthenticated ? authVM.userProfileImage : nil
        }
    }

    private var avatarPicker: some View {
        let currentImage = profileImage
        let isAuthenticated = authVM.isAuthenticated

        return PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            Group {
                if let image = currentImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(isAuthenticated ? .blue : .secondary)
                }
            }
            .frame(width: 80, height: 80)
        }
        .buttonStyle(.plain)
        .disabled(!isAuthenticated)
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("profile_account", systemImage: "person.crop.circle.fill")
                .font(.headline)
                .foregroundStyle(.blue)

            if authVM.isAuthenticated {
                logoutButton
            } else {
                authButtons
            }

            Text(authVM.isAuthenticated ? "profile_storage_cloud" : "profile_storage_local")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private var logoutButton: some View {
        Button(role: .destructive) {
            showLogoutAlert = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("action_logout")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var authButtons: some View {
        HStack(spacing: 12) {
            Button {
                showLoginSheet = true
            } label: {
                HStack {
                    Image(systemName: "person.badge.key.fill")
                    Text("action_login")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                showRegisterSheet = true
            } label: {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("action_register")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Storage Section

    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("profile_storage", systemImage: "externaldrive.fill")
                .font(.headline)
                .foregroundStyle(.green)

            HStack {
                Image(systemName: "cloud.fill")
                    .foregroundStyle(authVM.isAuthenticated ? .blue : .secondary)
                    .frame(width: 24)
                Text("profile_cloud_collection")
                Spacer()
                Text(authVM.isAuthenticated ? "\(cloudVM.cloudCollection.count) mangas" : "-")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)

            Divider()

            HStack {
                Image(systemName: "internaldrive.fill")
                    .foregroundStyle(.green)
                    .frame(width: 24)
                Text("profile_local_collection")
                Spacer()
                Text("profile_session_active")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    MacProfileView()
        .environment(AuthViewModel())
        .environment(CloudCollectionViewModel(authVM: AuthViewModel()))
        .environment(TranslationService())
}
