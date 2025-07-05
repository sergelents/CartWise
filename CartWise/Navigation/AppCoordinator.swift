//
//  AppCoordinator.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//

import SwiftUI

import SwiftUI

class AppCoordinator: ObservableObject {
    @Published var selectedTab: TabItem = .yourList
    
    func selectTab(_ tab: TabItem) {
        selectedTab = tab
    }
}

enum TabItem: String, CaseIterable {
    case yourList = "Your List"
    case searchItems = "Search Items"
    case addItems = "Add Items"
    case myProfile = "My Profile"
    
    var iconName: String {
        switch self {
        case .yourList: return "list.bullet"
        case .searchItems: return "magnifyingglass"
        case .addItems: return "plus.circle"
        case .myProfile: return "person.circle"
        }
    }
    
    var selectedIconName: String {
        switch self {
        case .yourList: return "list.bullet"
        case .searchItems: return "magnifyingglass"
        case .addItems: return "plus.circle.fill"
        case .myProfile: return "person.circle.fill"
        }
    }
}



struct AppCoordinatorView: View {
    @ObservedObject var coordinator: AppCoordinator
    
    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            YourListView()
                .tabItem {
                    Image(systemName: coordinator.selectedTab == .yourList ?
                          TabItem.yourList.selectedIconName : TabItem.yourList.iconName)
                    Text(TabItem.yourList.rawValue)
                }
                .tag(TabItem.yourList)
            
            SearchItemsView()
                .tabItem {
                    Image(systemName: coordinator.selectedTab == .searchItems ?
                          TabItem.searchItems.selectedIconName : TabItem.searchItems.iconName)
                    Text(TabItem.searchItems.rawValue)
                }
                .tag(TabItem.searchItems)
            
            AddItemsView()
                .tabItem {
                    Image(systemName: coordinator.selectedTab == .addItems ?
                          TabItem.addItems.selectedIconName : TabItem.addItems.iconName)
                    Text(TabItem.addItems.rawValue)
                }
                .tag(TabItem.addItems)
            
            MyProfileView()
                .tabItem {
                    Image(systemName: coordinator.selectedTab == .myProfile ?
                          TabItem.myProfile.selectedIconName : TabItem.myProfile.iconName)
                    Text(TabItem.myProfile.rawValue)
                }
                .tag(TabItem.myProfile)
        }
    }
}
