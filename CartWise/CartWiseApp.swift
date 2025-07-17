//
//  CartWiseApp.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//

import SwiftUI

@main
struct CartWiseApp: App {
    let persistenceController = PersistenceController.shared // Your CoreData setup
    @StateObject private var appCoordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView(coordinator: appCoordinator)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

