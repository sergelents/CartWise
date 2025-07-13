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
    @State private var username = ""
    @State private var password = ""
    
    init() {
        self._viewModel = StateObject(wrappedValue: AuthViewModel(context: PersistenceController.shared.container.viewContext))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Username", text: $username)
                        .textContentType(.username)
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
                    Task { await viewModel.login(username: username, password: password) }
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
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
