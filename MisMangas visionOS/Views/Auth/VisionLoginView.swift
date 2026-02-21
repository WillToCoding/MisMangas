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
        VStack(spacing: 40) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "vision.pro")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)

                Text("nav_login")
                    .font(.system(size: 48, weight: .bold))
            }

            // Form
            VStack(spacing: 24) {
                // Email
                VStack(alignment: .leading, spacing: 8) {
                    Text("login_email")
                        .font(.headline)
                    TextField("email@example.com", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .frame(width: 400)
                }

                // Password
                VStack(alignment: .leading, spacing: 8) {
                    Text("login_password")
                        .font(.headline)
                    SecureField("login_password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .frame(width: 400)
                }

                // Login Button
                Button {
                    Task {
                        await login()
                    }
                } label: {
                    if authVM.isLoading {
                        ProgressView()
                            .controlSize(.regular)
                    } else {
                        Text("action_login")
                            .font(.title2.bold())
                            .frame(width: 400)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(email.isEmpty || password.isEmpty || authVM.isLoading)
            }
            .padding(40)
            .glassBackgroundEffect()

            // Error message
            if showError {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.headline)
                    .padding()
                    .background(.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(60)
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
