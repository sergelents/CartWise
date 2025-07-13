//
//  SignUpView.swift
//  CartWise
//
//  Created by Alex Kumar on 7/13/25.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel = AuthViewModel(context: PersistenceController.shared.container.viewContext)
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    @State private var username = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("CartWise")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                
                Spacer()
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Username")
                            .font(.headline)
                        TextField("Enter username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .textContentType(.username)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Password")
                            .font(.headline)
                        SecureField("Enter password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.password)
                    }
                }
                .padding(.horizontal)

                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }

                Button(action: {
                    Task {
                        await viewModel.signUp(username: username, password: password)
                        if viewModel.user != nil {
                            isLoggedIn = true
                        }
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(viewModel.isLoading || username.isEmpty || password.isEmpty)

                NavigationLink("Already have an account? Log In", destination: LoginView())
                    .padding(.top, 10)
                
                Spacer()
            }
            .navigationTitle("Sign Up")
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
