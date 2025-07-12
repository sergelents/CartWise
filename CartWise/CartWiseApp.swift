//
//  CartWiseApp.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//  Modified by Alex Kumar on 7/12/25

import SwiftUI

@main
struct CartWiseApp: App {
    @StateObject private var appCoordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView(coordinator: appCoordinator)
            
    init() {
            FirebaseApp.configure()
        }
        
        var body: some Scene {
            WindowGroup {
                LoginView() // Start with login screen
            }
        }
    }
}

