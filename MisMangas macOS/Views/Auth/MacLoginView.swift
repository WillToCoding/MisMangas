//
//  MacLoginView.swift
//  MisMangas macOS
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI
import SwiftData

struct MacLoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showRegister = false

    @Environment(AuthViewModel.self) private var authVM
    @Environment(CloudCollectionViewModel.self) private var cloudVM
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("nav_login")
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
                    Text("login_password")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    SecureField("••••••••", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                }
            }
            .padding(.horizontal)

            // Buttons
            VStack(spacing: 12) {
                Button {
                    Task {
                        await login()
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Text("action_login")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(email.isEmpty || password.isEmpty || isLoading)
                .keyboardShortcut(.defaultAction)

                Button("action_register") {
                    showRegister = true
                }
                .buttonStyle(.link)
                .disabled(isLoading)
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
        .frame(width: 400, height: 450)
        .alert("error_title", isPresented: $showError) {
            Button("action_ok", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showRegister) {
            MacRegisterView()
        }
    }

    // MARK: - Methods

    private func login() async {
        isLoading = true

        do {
            try await authVM.login(email: email, password: password)

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

#Preview {
    MacLoginView()
        .environment(AuthViewModel())
        .environment(CloudCollectionViewModel(authVM: AuthViewModel()))
        .modelContainer(.preview)
}
