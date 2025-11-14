//
//  LoginView.swift
//  CartWise
//
//  Created by Alex Kumar on 7/12/25.
//
import SwiftUI

struct LoginView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AuthViewModel
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false
    
    init() {
        _viewModel = StateObject(
            wrappedValue: AuthViewModel(context: PersistenceController.shared.container.viewContext)
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with back button and title
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Text("Login")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 30)
                
                // Form Fields
                VStack(alignment: .leading, spacing: 20) {
                    // Username Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AppColors.textPrimary)
                        
                        TextField("Enter your username", text: $username)
                            .font(.system(size: 14))
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .autocapitalization(.none)
                            .textContentType(.username)
                            .tint(.black)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AppColors.textPrimary)
                        
                        HStack {
                            if showPassword {
                                TextField("Enter your password", text: $password)
                                    .font(.system(size: 14))
                                    .textContentType(.password)
                            } else {
                                SecureField("Enter your password", text: $password)
                                    .font(.system(size: 14))
                                    .textContentType(.password)
                            }
                            
                            Button(action: {
                                showPassword.toggle()
                            }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .tint(.black)
                    }
                    
                    // Forgot Password Link
                    HStack {
                        Spacer()
                        Button(action: {
                            // Handle forgot password
                        }) {
                            Text("Forgot Password?")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                
                // Error Message
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(AppColors.accentRed)
                        .font(.system(size: 12))
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                }
                
                Spacer()
                
                // Login Button
                Button {
                    Task {
                        print("Login button tapped with username: \(username)")
                        await viewModel.login(username: username, password: password)
                        print("Login completed. User: \(String(describing: viewModel.user)), " +
                              "Error: \(String(describing: viewModel.error))")
                        if viewModel.user != nil {
                            isLoggedIn = true
                            print("User logged in successfully")
                        }
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Log In")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppColors.accentGreen)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .disabled(viewModel.isLoading || username.isEmpty || password.isEmpty)
                .opacity((viewModel.isLoading || username.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                
                // Sign Up Link
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    NavigationLink(destination: SignUpView()) {
                        Text("Sign Up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.accentGreen)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 30)
            }
            .background(Color(UIColor.systemGray6))
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
