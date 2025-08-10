//
//  AppCoordinator.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//
import SwiftUI
class AppCoordinator: ObservableObject {
    @Published var selectedTab: TabItem = .yourList
    @Published var showSplash = true
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    func selectTab(_ tab: TabItem) {
        selectedTab = tab
    }

    func logout() {
        isLoggedIn = false
    }

    func hideSplash() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showSplash = false
        }
    }
}
enum TabItem: String, CaseIterable {
    case yourList = "Your List"
    case searchItems = "Search Items"
    case addItems = "Add Items"
    case socialFeed = "Social Feed"
    case myProfile = "My Profile"
    var iconName: String {
        switch self {
        case .yourList: return "list.bullet"
        case .searchItems: return "magnifyingglass"
        case .addItems: return "plus.circle"
        case .socialFeed: return "bubble.left.and.bubble.right"
        case .myProfile: return "person.circle"
        }
    }
    var selectedIconName: String {
        switch self {
        case .yourList: return "list.bullet"
        case .searchItems: return "magnifyingglass"
        case .addItems: return "plus.circle.fill"
        case .socialFeed: return "bubble.left.and.bubble.right.fill"
        case .myProfile: return "person.circle.fill"
        }
    }
}
struct AppCoordinatorView: View {
    @ObservedObject var coordinator: AppCoordinator
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @EnvironmentObject var productViewModel: ProductViewModel

    var body: some View {
        ZStack {
            // Main app content
            Group {
                if isLoggedIn {
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
                        .tint(Color.accentColorBlue)
                    AddItemsView(availableTags: productViewModel.tags)
                        .tabItem {
                            Image(systemName: coordinator.selectedTab == .addItems ?
                                  TabItem.addItems.selectedIconName : TabItem.addItems.iconName)
                            Text(TabItem.addItems.rawValue)
                        }
                        .tag(TabItem.addItems)
                    SocialFeedView()
                        .tabItem {
                            Image(systemName: coordinator.selectedTab == .socialFeed ?
                                  TabItem.socialFeed.selectedIconName : TabItem.socialFeed.iconName)
                            Text(TabItem.socialFeed.rawValue)
                        }
                        .tag(TabItem.socialFeed)
                    MyProfileView()
                        .tabItem {
                            Image(systemName: coordinator.selectedTab == .myProfile ?
                                  TabItem.myProfile.selectedIconName : TabItem.myProfile.iconName)
                            Text(TabItem.myProfile.rawValue)
                        }
                        .tag(TabItem.myProfile)
                }.tint(Color.accentColorBlue)
            } else {
                LoginView()
            }
        }

        // Splash screen overlay
        if coordinator.showSplash {
            SplashScreenView()
                .transition(.opacity)
                .onAppear {
                    // Hide splash after 2.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        coordinator.hideSplash()
                    }
                }
        }
        }
    }
}
// This code was generated with the help of Claude, saving me 2 hours of research and development.
