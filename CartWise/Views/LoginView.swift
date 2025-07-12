//
//  LoginView.swift
//  CartWise
//
//  Created by Alex Kumar on 7/12/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .font(DesignSystem.bodyFont)
                        .padding()
                        .background(DesignSystem.backgroundColor)
                        .cornerRadius(8)
                    SecureField("Password", text: $password)
                        .font(DesignSystem.bodyFont)
                        .padding()
                        .background(DesignSystem.backgroundColor)
                        .cornerRadius(8)
                }
                
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(DesignSystem.bodyFont)
                }
                
                Button(action: {
                    Task { await viewModel.login(email: email, password: password) }
                }) {
                    Text("Log In")
                        .font(DesignSystem.buttonFont)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignSystem.primaryColor)
                        .cornerRadius(8)
                }
                
                NavigationLink("Don't have an account? Sign Up", destination: SignUpView())
                    .font(DesignSystem.bodyFont)
                    .foregroundColor(DesignSystem.accentColor)
            }
            .navigationTitle("Log In")
            .background(DesignSystem.backgroundColor)
        }
        .task {
            if viewModel.user != nil {
                await viewModel.loadUserData(userId: viewModel.user!.id)
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
