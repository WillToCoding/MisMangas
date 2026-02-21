//
//  RegisterView.swift
//  MisMangas
//
//  Created by Juan Carlos on 11/12/25.
//

import SwiftUI

struct RegisterView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false

    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            // MARK: - Campos de Registro
            Section {
                TextField("login_email", text: $email)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()

                SecureField("login_password", text: $password)
                    .textContentType(.newPassword)

                SecureField("register_confirm_password", text: $confirmPassword)
                    .textContentType(.newPassword)
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("register_password_hint")
                        .font(.caption)

                    if !password.isEmpty && password.count < 8 {
                        Label("register_password_short", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    if !confirmPassword.isEmpty && password != confirmPassword {
                        Label("register_password_mismatch", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            // MARK: - Validación Visual
            if !email.isEmpty || !password.isEmpty {
                Section("register_status") {
                    HStack {
                        Image(systemName: isValidEmail ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(isValidEmail ? .green : .secondary)
                        Text("register_valid_email")
                    }

                    HStack {
                        Image(systemName: password.count >= 8 ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(password.count >= 8 ? .green : .secondary)
                        Text("register_password_min")
                    }

                    HStack {
                        Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(passwordsMatch ? .green : .secondary)
                        Text("register_passwords_match")
                    }
                }
            }

            // MARK: - Botón de Registro
            Section {
                Button {
                    Task {
                        await register()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("action_register")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(!isFormValid || isLoading)
            }
        }
        .navigationTitle("nav_register")
        .navigationBarTitleDisplayMode(.inline)
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
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }
}

// MARK: - Preview
#Preview("Register View") {
    @Previewable @State var authVM = AuthViewModel()
    NavigationStack {
        RegisterView()
            .environment(authVM)
    }
}
