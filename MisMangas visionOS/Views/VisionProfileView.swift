//
//  VisionProfileView.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 26/02/26.
//

import SwiftUI
import PhotosUI

struct VisionProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Binding var showLogin: Bool
    @State private var showLogoutAlert = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(spacing: 50) {
                headerSection
                accountSection
                storageSection
                settingsLink
            }
            .padding(60)
            .frame(minWidth: 700)
        }
        .navigationTitle("nav_profile")
        .alert("profile_logout_title", isPresented: $showLogoutAlert) {
            Button("action_cancel", role: .cancel) { }
            Button("action_logout", role: .destructive) {
                authVM.logout()
            }
        } message: {
            Text("profile_logout_message")
        }
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
        .onChange(of: authVM.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                profileImage = authVM.userProfileImage
            } else {
                profileImage = nil
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        let currentImage = profileImage
        let isAuthenticated = authVM.isAuthenticated
        let email = authVM.userEmail

        return VStack(spacing: 20) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Group {
                    if let image = currentImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 100))
                            .foregroundStyle(.blue)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(!isAuthenticated)

            if isAuthenticated, let email {
                Text(email)
                    .font(.title.bold())

                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("profile_connected")
                        .foregroundStyle(.secondary)
                }
                .font(.title3)

                Text("profile_tap_to_change_avatar")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                Text("profile_not_connected")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text("profile_login_prompt")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Account Section

    private var accountSection: some View {
        let isAuthenticated = authVM.isAuthenticated

        return VStack(alignment: .leading, spacing: 20) {
            Label("profile_account", systemImage: "person.crop.circle.fill")
                .font(.title2.bold())
                .foregroundStyle(.blue)

            if isAuthenticated {
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
                    .font(.title3)
                }
            } else {
                Button {
                    showLogin = true
                } label: {
                    HStack {
                        Image(systemName: "person.badge.key.fill")
                        Text("action_login")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .font(.title3)
                }
                .buttonStyle(.borderedProminent)
            }

            Text(isAuthenticated ? "profile_storage_cloud" : "profile_storage_local")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(30)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Storage Section

    private var storageSection: some View {
        let isAuthenticated = authVM.isAuthenticated
        let collectionCount = cloudVM.cloudCollection.count

        return VStack(alignment: .leading, spacing: 20) {
            Label("profile_storage", systemImage: "externaldrive.fill")
                .font(.title2.bold())
                .foregroundStyle(.green)

            HStack {
                Image(systemName: "cloud.fill")
                    .foregroundStyle(isAuthenticated ? .blue : .secondary)
                Text("profile_cloud_collection")
                Spacer()
                Text(isAuthenticated ? "\(collectionCount) mangas" : "-")
                    .foregroundStyle(.secondary)
            }
            .font(.title3)

            HStack {
                Image(systemName: "internaldrive.fill")
                    .foregroundStyle(.green)
                Text("profile_local_collection")
                Spacer()
                Text("profile_session_active")
                    .foregroundStyle(.secondary)
            }
            .font(.title3)
        }
        .padding(30)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.green.opacity(0.05), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Settings Link

    private var settingsLink: some View {
        NavigationLink(destination: VisionSettingsView()) {
            HStack {
                Label("settings_title", systemImage: "gearshape.fill")
                    .font(.title3.bold())
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var showLogin = false
    let authVM = AuthViewModel()

    NavigationStack {
        VisionProfileView(showLogin: $showLogin)
    }
    .environment(authVM)
    .environment(CloudCollectionViewModel(authVM: authVM))
}
