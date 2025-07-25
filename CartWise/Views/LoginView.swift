//
//  LoginView.swift
//  CartWise
//
//  Created by Alex Kumar on 7/12/25.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: AuthViewModel
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    @State private var username = ""
    @State private var password = ""

    init() {
        _viewModel = StateObject(wrappedValue: AuthViewModel(context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Shopping Cart Icon
                Image(systemName: "cart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.accentGreen)
                    .padding(.top, 50)
                
                // App Logo/Title
                Text("CartWise")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.top, 10)
                
                Spacer()
                
                VStack(spacing: 20) {
                    // Username Field
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Username")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        TextField("Enter username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .textContentType(.username)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Password")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        SecureField("Enter password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.password)
                    }
                }
                .padding(.horizontal)

                // Error Message
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(AppColors.accentRed)
                        .font(.caption)
                        .padding(.horizontal)
                }

                // Login Button
                Button(action: {
                    Task {
                        print("Login button tapped with username: \(username)")
                        await viewModel.login(username: username, password: password)
                        print("Login completed. User: \(String(describing: viewModel.user)), Error: \(String(describing: viewModel.error))")
                        if viewModel.user != nil {
                            isLoggedIn = true
                            print("User logged in successfully")
                        }
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textSecondary))
                            .scaleEffect(0.8)
                    } else {
                        Text("Log In")
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppColors.accentGreen)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(viewModel.isLoading || username.isEmpty || password.isEmpty)

                // Sign Up Link
                NavigationLink("Don't have an account? Sign Up", destination: SignUpView())
                    .foregroundColor(AppColors.textPrimary)
                    .font(.system(size: 16, weight: .medium))
                    .padding(.top, 10)
                
                Spacer()
            }
            .background(AppColors.backgroundPrimary)
            .navigationTitle("Log In")
            .navigationBarHidden(true)
        }
    }
}

// Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
