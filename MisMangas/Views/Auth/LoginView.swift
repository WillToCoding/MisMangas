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
                        .accessibilityLabel(String(localized: "accessibility_email_field"))
                        .accessibilityHint(String(localized: "accessibility_enter_email"))

                    SecureField("login_password", text: $password)
                        .textContentType(.password)
                        .accessibilityLabel(String(localized: "accessibility_password_field"))
                        .accessibilityHint(String(localized: "accessibility_enter_password"))
                } header: {
                    Text("login_credentials")
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
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
                                    .accessibilityLabel(String(localized: "accessibility_logging_in"))
                            } else {
                                Text("action_login")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                    .accessibilityLabel(isLoading ? String(localized: "accessibility_logging_in") : String(localized: "action_login"))
                    .accessibilityHint(String(localized: "accessibility_login_hint"))

                    NavigationLink("action_register") {
                        RegisterView()
                    }
                    .disabled(isLoading)
                    .accessibilityHint(String(localized: "accessibility_register_hint"))
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
            #if os(iOS)
            HapticFeedback.success.trigger()
            #endif
            // Si el login es exitoso, cerramos la vista
            dismiss()
        } catch {
            #if os(iOS)
            HapticFeedback.error.trigger()
            #endif
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
