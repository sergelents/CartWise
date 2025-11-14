//
//  SignUpView.swift
//  CartWise
//
//  Created by Alex Kumar on 7/13/25.
//
import SwiftUI

struct SignUpView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: AuthViewModel
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    @State private var fullName = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    init() {
        _viewModel = StateObject(
            wrappedValue: AuthViewModel(context: PersistenceController.shared.container.viewContext)
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Shopping Bag Icon
                    ZStack {
                        Circle()
                            .fill(AppColors.accentGreen.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "bag.fill")
                            .font(.system(size: 36))
                            .foregroundColor(AppColors.accentGreen)
                    }
                    .padding(.top, 40)
                    
                    // Title
                    Text("Create Account")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.top, 20)
                    
                    // Subtitle
                    Text("Track prices, compare stores, and save on every shopping trip.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    
                    // Form Fields
                    VStack(alignment: .leading, spacing: 16) {
                        // Full Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Enter your full name", text: $fullName)
                                .font(.system(size: 14))
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .textContentType(.name)
                                .tint(.black)
                        }
                        
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
                                        .textContentType(.newPassword)
                                } else {
                                    SecureField("Enter your password", text: $password)
                                        .font(.system(size: 14))
                                        .textContentType(.newPassword)
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
                            
                            Text("Must be at least 8 characters.")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(AppColors.textPrimary)
                            
                            HStack {
                                if showConfirmPassword {
                                    TextField("Confirm your password", text: $confirmPassword)
                                        .font(.system(size: 14))
                                        .textContentType(.newPassword)
                                } else {
                                    SecureField("Confirm your password", text: $confirmPassword)
                                        .font(.system(size: 14))
                                        .textContentType(.newPassword)
                                }
                                
                                Button(action: {
                                    showConfirmPassword.toggle()
                                }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                    
                    // Error Message
                    if let error = viewModel.error {
                        Text(error)
                            .foregroundColor(AppColors.accentRed)
                            .font(.system(size: 12))
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                    }
                    
                    // Create Account Button
                    Button {
                        Task {
                            guard password == confirmPassword else {
                                viewModel.error = "Passwords do not match"
                                return
                            }
                            guard password.count >= 8 else {
                                viewModel.error = "Password must be at least 8 characters"
                                return
                            }
                            print("Sign up button tapped with username: \(username)")
                            await viewModel.signUp(username: username, password: password, fullName: fullName)
                            print("Sign up completed. User: \(String(describing: viewModel.user)), " +
                                  "Error: \(String(describing: viewModel.error))")
                            if viewModel.user != nil {
                                isLoggedIn = true
                                print("User signed up successfully")
                            }
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Create Account")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColors.accentGreen)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .disabled(viewModel.isLoading || username.isEmpty || password.isEmpty || fullName.isEmpty || confirmPassword.isEmpty)
                    .opacity((viewModel.isLoading || username.isEmpty || password.isEmpty || fullName.isEmpty || confirmPassword.isEmpty) ? 0.6 : 1.0)
                    
                    // Or continue with
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("Or continue with")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                            .fixedSize()
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    
                    // Social Sign In Buttons
                    HStack(spacing: 16) {
                        // Google Sign In
                        Button(action: {
                            // Handle Google sign in
                        }) {
                            HStack {
                                Image(systemName: "g.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                                
                                Text("Google")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Apple Sign In
                        Button(action: {
                            // Handle Apple sign in
                        }) {
                            HStack {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text("Apple")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Log In Link
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        NavigationLink(destination: LoginView()) {
                            Text("Log In")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.accentGreen)
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 30)
                }
            }
            .background(Color(UIColor.systemGray6))
            .navigationBarHidden(true)
        }
    }
}

// Preview
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
