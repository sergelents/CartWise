//
//  AppCoordinator.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//
import SwiftUI

@MainActor
class AppCoordinator: ObservableObject {
    @Published var selectedTab: TabItem = .yourList
    @Published var showSplash = true
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    // MARK: - Sub-Coordinators
    @Published var shoppingListCoordinator: ShoppingListCoordinator?
    @Published var searchItemsCoordinator: SearchItemsCoordinator?
    @Published var addItemsCoordinator: AddItemsCoordinator?
    @Published var socialFeedCoordinator: SocialFeedCoordinator?
    @Published var myProfileCoordinator: MyProfileCoordinator?

    // MARK: - Dependencies
    private let productViewModel: ProductViewModel

    init(productViewModel: ProductViewModel) {
        self.productViewModel = productViewModel
    }

    func selectTab(_ tab: TabItem) {
        selectedTab = tab
    }

    func logout() {
        isLoggedIn = false
        // Clean up all coordinators on logout
        cleanupCoordinators()
    }

    func hideSplash() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showSplash = false
        }
    }

    // MARK: - Sub-Coordinator Management

    func getShoppingListCoordinator() -> ShoppingListCoordinator {
        if shoppingListCoordinator == nil {
            shoppingListCoordinator = ShoppingListCoordinator(productViewModel: productViewModel)
        }
        return shoppingListCoordinator!
    }

    func getSearchItemsCoordinator() -> SearchItemsCoordinator {
        if searchItemsCoordinator == nil {
            searchItemsCoordinator = SearchItemsCoordinator(productViewModel: productViewModel)
        }
        return searchItemsCoordinator!
    }

    func getAddItemsCoordinator() -> AddItemsCoordinator {
        if addItemsCoordinator == nil {
            addItemsCoordinator = AddItemsCoordinator(productViewModel: productViewModel)
        }
        return addItemsCoordinator!
    }

    func getSocialFeedCoordinator() -> SocialFeedCoordinator {
        if socialFeedCoordinator == nil {
            socialFeedCoordinator = SocialFeedCoordinator()
        }
        return socialFeedCoordinator!
    }

    func getMyProfileCoordinator() -> MyProfileCoordinator {
        if myProfileCoordinator == nil {
            myProfileCoordinator = MyProfileCoordinator(productViewModel: productViewModel)
        }
        return myProfileCoordinator!
    }

    private func cleanupCoordinators() {
        shoppingListCoordinator = nil
        searchItemsCoordinator = nil
        addItemsCoordinator = nil
        socialFeedCoordinator = nil
        myProfileCoordinator = nil
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
                            .environmentObject(coordinator.getShoppingListCoordinator())
                            .tabItem {
                                Image(systemName: coordinator.selectedTab == .yourList ?
                                      TabItem.yourList.selectedIconName : TabItem.yourList.iconName)
                                Text(TabItem.yourList.rawValue)
                            }
                            .tag(TabItem.yourList)

                        SearchItemsView()
                            .environmentObject(coordinator.getSearchItemsCoordinator())
                            .tabItem {
                                Image(systemName: coordinator.selectedTab == .searchItems ?
                                      TabItem.searchItems.selectedIconName : TabItem.searchItems.iconName)
                                Text(TabItem.searchItems.rawValue)
                            }
                            .tag(TabItem.searchItems)
                            .tint(Color.accentColorBlue)

                        AddItemsView(availableTags: productViewModel.tags)
                            .environmentObject(coordinator.getAddItemsCoordinator())
                            .tabItem {
                                Image(systemName: coordinator.selectedTab == .addItems ?
                                      TabItem.addItems.selectedIconName : TabItem.addItems.iconName)
                                Text(TabItem.addItems.rawValue)
                            }
                            .tag(TabItem.addItems)

                        SocialFeedView()
                            .environmentObject(coordinator.getSocialFeedCoordinator())
                            .tabItem {
                                Image(systemName: coordinator.selectedTab == .socialFeed ?
                                      TabItem.socialFeed.selectedIconName : TabItem.socialFeed.iconName)
                                Text(TabItem.socialFeed.rawValue)
                            }
                            .tag(TabItem.socialFeed)

                        MyProfileView()
                            .environmentObject(coordinator.getMyProfileCoordinator())
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
