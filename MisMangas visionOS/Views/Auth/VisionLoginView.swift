//
//  VisionLoginView.swift
//  MisMangas visionOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct VisionLoginView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                // Header
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "vision.pro")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)

                        Text("nav_login")
                            .font(.largeTitle.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }

                // Campos de login
                Section {
                    TextField("login_email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    SecureField("login_password", text: $password)
                        .textContentType(.password)
                } header: {
                    Text("profile_account")
                }

                // Login Button
                Section {
                    Button {
                        Task {
                            await login()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if authVM.isLoading {
                                ProgressView()
                            } else {
                                Text("action_login")
                                    .font(.headline)
                            }
                            Spacer()
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || authVM.isLoading)
                }

                // Error message
                if showError {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("nav_login")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func login() async {
        showError = false

        do {
            try await authVM.login(email: email, password: password)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    VisionLoginView()
        .environment(AuthViewModel())
}
