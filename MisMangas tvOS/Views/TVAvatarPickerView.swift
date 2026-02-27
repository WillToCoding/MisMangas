//
//  TVAvatarPickerView.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 25/2/26.
//

import SwiftUI

struct TVAvatarPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let onAvatarSelected: (Avatar) -> Void

    @State private var selectedAvatar: Avatar?
    @FocusState private var focusedAvatar: Avatar?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 60) {
                // Header con preview
                headerSection
                    .padding(.horizontal, 80)

                // Categorías con scroll horizontal
                ForEach(AvatarCategory.allCases) { category in
                    avatarCategorySection(category)
                }

                // Botón confirmar
                if selectedAvatar != nil {
                    confirmSection
                        .padding(.horizontal, 80)
                }

                Spacer(minLength: 100)
            }
            .padding(.vertical, 60)
        }
        .background(Color.black.opacity(0.95))
        .onExitCommand {
            dismiss()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 50) {
            // Botón volver
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            // Preview del avatar seleccionado/enfocado
            VStack(spacing: 16) {
                if let avatar = focusedAvatar ?? selectedAvatar {
                    Image(avatar.assetName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(selectedAvatar == avatar ? Color.blue : Color.white.opacity(0.3), lineWidth: 4)
                        }

                    Text(avatar.displayName)
                        .font(.system(size: 28, weight: .semibold))
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .foregroundStyle(.secondary)

                    Text("profile_select_avatar")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: focusedAvatar)

            Spacer()

            // Espacio para balancear
            Color.clear
                .frame(width: 50, height: 50)
        }
    }

    // MARK: - Category Section

    private func avatarCategorySection(_ category: AvatarCategory) -> some View {
        VStack(alignment: .leading, spacing: 30) {
            // Header de categoría
            Label(category.displayName, systemImage: category.icon)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(category.color)
                .padding(.horizontal, 80)

            // Scroll horizontal de avatares
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 30) {
                    ForEach(category.avatars) { avatar in
                        avatarCard(avatar)
                    }
                }
                .padding(.horizontal, 80)
            }
            .focusSection()
        }
    }

    private func avatarCard(_ avatar: Avatar) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedAvatar = avatar
            }
        } label: {
            VStack(spacing: 12) {
                Image(avatar.assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(selectedAvatar == avatar ? Color.blue : Color.clear, lineWidth: 4)
                    }
                    .shadow(color: selectedAvatar == avatar ? .blue.opacity(0.5) : .clear, radius: 10)

                Text(avatar.displayName)
                    .font(.system(size: 22))
                    .foregroundStyle(selectedAvatar == avatar ? .blue : .primary)
                    .lineLimit(1)
            }
            .padding(16)
        }
        .buttonStyle(.card)
        .focused($focusedAvatar, equals: avatar)
    }

    // MARK: - Confirm Section

    private var confirmSection: some View {
        HStack {
            Spacer()

            Button {
                if let avatar = selectedAvatar {
                    onAvatarSelected(avatar)
                    dismiss()
                }
            } label: {
                Label("action_confirm", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .padding(.horizontal, 40)
            }
            .buttonStyle(.borderedProminent)
            .focusSection()

            Spacer()
        }
    }
}

#Preview {
    TVAvatarPickerView { avatar in
        print("Selected: \(avatar.displayName)")
    }
}
