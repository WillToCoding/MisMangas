//
//  TVLoginView.swift
//  MisMangas tvOS
//
//  Created by Juan Carlos on 13/12/25.
//

import SwiftUI

struct TVLoginView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    var body: some View {
        VStack(spacing: 60) {
            Text("nav_login")
                .font(.system(size: 72, weight: .bold))

            VStack(spacing: 40) {
                TextField("login_email", text: $email)
                    .font(.system(size: 36))
                    .frame(width: 800)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .focused($focusedField, equals: .email)
                    .onSubmit {
                        focusedField = .password
                    }

                SecureField("login_password", text: $password)
                    .font(.system(size: 36))
                    .frame(width: 800)
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .onSubmit {
                        focusedField = nil
                    }
            }

            HStack(spacing: 40) {
                Button("action_cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .font(.system(size: 32))

                Button("action_login") {
                    Task {
                        do {
                            try await authVM.login(email: email, password: password)
                            dismiss()
                        } catch {
                            print("[TV] Error login: \(error)")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .font(.system(size: 32))
                .disabled(email.isEmpty || password.isEmpty)
            }

            if let error = authVM.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.system(size: 28))
            }
        }
        .padding(120)
        .onAppear {
            focusedField = .email
        }
    }
}

#Preview {
    TVLoginView()
        .environment(AuthViewModel())
}
