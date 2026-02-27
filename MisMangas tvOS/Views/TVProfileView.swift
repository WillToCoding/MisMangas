//
//  TVProfileView.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct TVProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @State private var showLogin = false
    @State private var showLogoutAlert = false
    @State private var showAvatarPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 60) {
                // MARK: - Header Perfil
                Button {
                    if authVM.isAuthenticated {
                        showAvatarPicker = true
                    }
                } label: {
                    VStack(spacing: 30) {
                        profileImage
                            .frame(width: 150, height: 150)

                        if authVM.isAuthenticated, let email = authVM.userEmail {
                            Text(email)
                                .font(.system(size: 40, weight: .semibold))

                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("profile_connected")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.system(size: 28))

                            Text("profile_tap_to_change_avatar")
                                .font(.system(size: 24))
                                .foregroundStyle(.tertiary)
                        } else {
                            Text("profile_not_connected")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary)

                            Text("profile_login_prompt")
                                .font(.system(size: 28))
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(50)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.card)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 24))
                .focusSection()

                // MARK: - Cuenta
                accountSection

                // MARK: - Almacenamiento
                storageSection

                // MARK: - Ajustes
                settingsLink

                Spacer(minLength: 50)
            }
            .padding(80)
        }
        .navigationTitle("tab_profile")
        .sheet(isPresented: $showLogin) {
            TVLoginView()
        }
        .alert("profile_logout_title", isPresented: $showLogoutAlert) {
            Button("action_cancel", role: .cancel) { }
            Button("action_logout", role: .destructive) {
                authVM.logout()
            }
        } message: {
            Text("profile_logout_message")
        }
        .sheet(isPresented: $showAvatarPicker) {
            TVAvatarPickerView { avatar in
                authVM.saveAvatar(avatar)
            }
        }
    }

    // MARK: - Profile Image

    private var profileImage: some View {
        Group {
            if let avatar = authVM.userAvatar {
                Image(avatar.assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(.blue.opacity(0.5), lineWidth: 4)
                    }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.blue)
            }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Label("profile_account", systemImage: "person.crop.circle.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.blue)

            if authVM.isAuthenticated {
                Button {
                    showLogoutAlert = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("action_logout")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
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
                    .font(.system(size: 28, weight: .semibold))
                }
                .buttonStyle(.bordered)
            }

            Text(authVM.isAuthenticated ? "profile_storage_cloud" : "profile_storage_local")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Storage Section

    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Label("profile_storage", systemImage: "externaldrive.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.green)

            HStack {
                Image(systemName: "cloud.fill")
                    .foregroundStyle(authVM.isAuthenticated ? .blue : .secondary)
                    .font(.system(size: 28))
                Text("profile_cloud_collection")
                    .font(.system(size: 28))
                Spacer()
                if authVM.isAuthenticated {
                    Text("\(cloudVM.cloudCollection.count) mangas")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                } else {
                    Text("-")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Image(systemName: "internaldrive.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 28))
                Text("profile_local_collection")
                    .font(.system(size: 28))
                Spacer()
                Text("profile_session_active")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.green.opacity(0.05), in: RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Settings Link

    private var settingsLink: some View {
        NavigationLink(destination: TVSettingsView()) {
            HStack {
                Label("settings_title", systemImage: "gearshape.fill")
                    .font(.system(size: 32, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }
            .padding(30)
            .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .focusSection()
    }
}

#Preview {
    let authVM = AuthViewModel()
    NavigationStack {
        TVProfileView()
    }
    .environment(authVM)
    .environment(CloudCollectionViewModel(authVM: authVM))
}
