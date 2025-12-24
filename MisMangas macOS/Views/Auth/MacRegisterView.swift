//
//  MacRegisterView.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI
import SwiftData

struct MacRegisterView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false

    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.badge.plus.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)

                Text("nav_register")
                    .font(.title.bold())

                Text("app_name")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)

            // Form
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("login_email")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("email@example.com", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("register_password_hint")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    SecureField("••••••••", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("register_confirm_password")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    SecureField("••••••••", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                }

                // Validation indicators
                if !email.isEmpty || !password.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ValidationRow(
                            isValid: isValidEmail,
                            text: String(localized: "register_valid_email")
                        )

                        ValidationRow(
                            isValid: password.count >= 8,
                            text: String(localized: "register_password_min")
                        )

                        ValidationRow(
                            isValid: passwordsMatch,
                            text: String(localized: "register_passwords_match")
                        )
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal)

            // Buttons
            VStack(spacing: 12) {
                Button {
                    Task {
                        await register()
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Text("action_register")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!isFormValid || isLoading)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal)

            Spacer()

            // Cancel button
            Button("action_cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .disabled(isLoading)
            .keyboardShortcut(.cancelAction)
            .padding(.bottom)
        }
        .frame(width: 450, height: 550)
        .alert("error_title", isPresented: $showError) {
            Button("action_ok", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Computed Properties

    private var isValidEmail: Bool {
        email.contains("@") && email.contains(".")
    }

    private var passwordsMatch: Bool {
        !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
    }

    private var isFormValid: Bool {
        isValidEmail &&
        password.count >= 8 &&
        passwordsMatch
    }

    // MARK: - Methods

    private func register() async {
        isLoading = true

        do {
            try await authVM.register(email: email, password: password)

            // Sincronizar colección local a la nube
            await syncLocalToCloud()

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    private func syncLocalToCloud() async {
        // Obtener todos los mangas locales
        let descriptor = FetchDescriptor<Model>(sortBy: [SortDescriptor(\.addedDate)])
        guard let localMangas = try? modelContext.fetch(descriptor), !localMangas.isEmpty else {
            print("No hay mangas locales para sincronizar")
            return
        }

        print("Sincronizando \(localMangas.count) mangas locales a la nube...")

        for manga in localMangas {
            do {
                // Crear un Manga temporal desde Model para poder subirlo
                let mangaToSync = Manga(
                    id: manga.id,
                    title: manga.title,
                    titleEnglish: manga.titleEnglish,
                    titleJapanese: nil,
                    status: "",
                    score: manga.score,
                    volumes: manga.totalVolumes,
                    chapters: nil,
                    startDate: nil,
                    endDate: nil,
                    sypnosis: nil,
                    background: nil,
                    mainPicture: manga.mainPicture,
                    url: "",
                    authors: [],
                    genres: [],
                    themes: [],
                    demographics: []
                )

                try await cloudVM.addToCollection(
                    manga: mangaToSync,
                    volumesOwned: manga.volumesOwned,
                    readingVolume: manga.currentReadingVolume,
                    completeCollection: manga.hasCompleteCollection
                )
                print("✓ Sincronizado: \(manga.title)")
            } catch {
                print("✗ Error sincronizando \(manga.title): \(error)")
            }
        }

        print("Sincronización completada")
    }
}

// MARK: - Validation Row
struct ValidationRow: View {
    let isValid: Bool
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundStyle(isValid ? .green : .secondary)

            Text(text)
                .font(.caption)
                .foregroundStyle(isValid ? .primary : .secondary)
        }
    }
}

#Preview {
    MacRegisterView()
        .environment(AuthViewModel())
        .environment(CloudCollectionViewModel(authVM: AuthViewModel()))
        .modelContainer(.preview)
}
