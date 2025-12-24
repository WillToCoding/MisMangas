//
//  LoginView.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false

    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Campos de Login
                Section {
                    TextField("login_email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()

                    SecureField("login_password", text: $password)
                        .textContentType(.password)
                }

                // MARK: - Botones
                Section {
                    Button {
                        Task {
                            await login()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("action_login")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)

                    NavigationLink("action_register") {
                        RegisterView()
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("nav_login")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action_cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
            .alert("error_title", isPresented: $showError) {
                Button("action_ok", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Methods

    private func login() async {
        isLoading = true

        do {
            try await authVM.login(email: email, password: password)
            // Si el login es exitoso, cerramos la vista
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }
}

// MARK: - Preview
#Preview("Login View") {
    @Previewable @State var authVM = AuthViewModel()
    LoginView()
        .environment(authVM)
}
