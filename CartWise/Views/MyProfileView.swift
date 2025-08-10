//
//  MyProfileView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//
import SwiftUI
import CoreData
struct MyProfileView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @EnvironmentObject var productViewModel: ProductViewModel
    @State private var currentUsername: String = ""
    @State private var isLoadingUser: Bool = true
    @State private var showAddLocation: Bool = false
    @State private var selectedTab: ProfileTab = .favorites
    @AppStorage("profileIconName") private var profileIconName: String = "person.crop.circle.fill"
    @State private var isAvatarPickerPresented: Bool = false
    enum ProfileTab: String, CaseIterable {
        case favorites = "Favorites"
        case locations = "Locations"
        case reputation = "Reputation"
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppColors.backgroundSecondary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Card
                        ProfileCard(
                            currentUsername: currentUsername,
                            isLoadingUser: isLoadingUser,
                            profileIconName: profileIconName,
                            onAvatarTapped: { isAvatarPickerPresented = true }
                        )

                        // Tabbed Content
                        TabbedContentView(selectedTab: $selectedTab)

                        // Logout Button
                        LogoutButton(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                // Clear the current username when logging out
                                UserDefaults.standard.removeObject(forKey: "currentUsername")
                                isLoggedIn = false
                            }
                        })
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SampleDataToggleButton()
                }
            }
            .task {
                await loadCurrentUser()
            }
            .sheet(isPresented: $showAddLocation) {
                AddLocationView()
                    .environmentObject(productViewModel)
            }
            .sheet(isPresented: $isAvatarPickerPresented) {
                ProfileIconPickerView(selectedIcon: $profileIconName)
            }
        }
    }
    private func loadCurrentUser() async {
        isLoadingUser = true
        do {
            let context = PersistenceController.shared.container.viewContext
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            // Since we don't have a direct way to identify the current user,
            // we'll fetch the most recently created user (assuming the last logged in user)
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \UserEntity.createdAt, ascending: false)]
            fetchRequest.fetchLimit = 1
            let users = try context.fetch(fetchRequest)
            if let currentUser = users.first, let username = currentUser.username {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentUsername = username
                        isLoadingUser = false
                    }
                }
            } else {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentUsername = "User"
                        isLoadingUser = false
                    }
                }
            }
        } catch {
            print("Error loading current user: \(error)")
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentUsername = "User"
                    isLoadingUser = false
                }
            }
        }
    }
}

// MARK: - Tabbed Content View
struct TabbedContentView: View {
    @Binding var selectedTab: MyProfileView.ProfileTab

    var body: some View {
        VStack(spacing: 0) {
            // Tab Selector
            TabSelector(selectedTab: $selectedTab)

            // Tab Content
            VStack(spacing: 0) {
                if selectedTab == .favorites {
                    FavoriteItemsView()
                        .transition(.opacity)
                } else if selectedTab == .locations {
                    LocationsSectionView()
                        .transition(.opacity)
                } else if selectedTab == .reputation {
                    ReputationTabView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
}

// MARK: - Tab Selector
struct TabSelector: View {
    @Binding var selectedTab: MyProfileView.ProfileTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MyProfileView.ProfileTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.poppins(size: 16, weight: selectedTab == tab ? .semibold : .medium))
                            .foregroundColor(selectedTab == tab ? AppColors.accentGreen : .gray)

                        // Underline indicator
                        Rectangle()
                            .fill(selectedTab == tab ? AppColors.accentGreen : Color.clear)
                            .frame(height: 2)
                            .cornerRadius(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// MARK: - Profile Card Component
struct ProfileCard: View {
    let currentUsername: String
    let isLoadingUser: Bool
    let profileIconName: String
    let onAvatarTapped: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Profile Avatar
            Button(action: onAvatarTapped) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    AppColors.accentGreen.opacity(0.15),
                                    AppColors.accentGreen.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 92, height: 92)
                        .overlay(
                            Circle()
                                .stroke(AppColors.accentGreen.opacity(0.2), lineWidth: 1)
                        )
                    Image(systemName: profileIconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .foregroundColor(AppColors.accentGreen)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 16)

            // User Info
            VStack(spacing: 8) {
                if isLoadingUser {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.vertical, 8)
                } else {
                    Text(currentUsername.isEmpty ? "User" : currentUsername)
                        .font(.poppins(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                }

                Text("Manage your account and preferences")
                    .font(.poppins(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
}

// MARK: - Profile Icon Picker
struct ProfileIconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    private let icons: [String] = [
        "person.crop.circle.fill",
        "person.circle.fill",
        "person.fill",
        "person.2.circle.fill",
        "cart.fill",
        "star.circle.fill",
        "bolt.circle.fill",
        "leaf.circle.fill",
        "heart.circle.fill"
    ]
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                icon == selectedIcon ? AppColors.accentGreen : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                                Image(systemName: icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 48, height: 48)
                                    .foregroundColor(AppColors.accentGreen)
                                    .padding(20)
                            }
                            .frame(height: 100)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(16)
            }
            .background(AppColors.backgroundSecondary.ignoresSafeArea())
            .navigationTitle("Choose an Icon")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Logout Button Component
struct LogoutButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .medium))
                Text("Log Out")
                    .font(.poppins(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppColors.accentRed,
                                AppColors.accentRed.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: AppColors.accentRed.opacity(0.25), radius: 8, x: 0, y: 4)
            )
        }
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.2), value: true)
    }
}

// MARK: - Reputation Tab View
struct ReputationTabView: View {
    @State private var userUpdates: Int = 0
    @State private var userLevel: String = "New Shopper"
    @State private var isLoading: Bool = true

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)

                    Text("Loading reputation data...")
                        .font(.poppins(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ReputationCardView(updates: userUpdates, level: userLevel)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 20)
        .task {
            await loadUserReputation()
        }
        .onAppear {
            Task {
                await loadUserReputation()
            }
        }
    }

    private func loadUserReputation() async {
        if let reputation = await ReputationManager.shared.getCurrentUserReputation() {
            await MainActor.run {
                userUpdates = reputation.updates
                userLevel = reputation.level
                isLoading = false
            }
        } else {
            await MainActor.run {
                userUpdates = 0
                userLevel = "New Shopper"
                isLoading = false
            }
        }
    }
}

// MARK: - Sample Data Toggle Button
struct SampleDataToggleButton: View {
    @State private var hasSampleData = false
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Button {
            Task {
                if hasSampleData {
                    await removeSampleData()
                } else {
                    await addSampleData()
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isProcessing ? "clock" : (hasSampleData ? "trash" : "plus.circle"))
                    .font(.system(size: 14, weight: .medium))
                Text(isProcessing ? "Loading..." : (hasSampleData ? "Remove Sample Data" : "Load Sample Data"))
                    .font(.poppins(size: 14, weight: .medium))
            }
            .foregroundColor(isProcessing ? .gray : (hasSampleData ? .red : AppColors.accentGreen))
        }
        .disabled(isProcessing)
        .alert("Sample Data", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .task {
            await checkSampleDataStatus()
        }
        .onAppear {
            Task {
                await checkSampleDataStatus()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SampleDataCleared"))) { _ in
            Task {
                await checkSampleDataStatus()
            }
        }
    }
    
    private func checkSampleDataStatus() async {
        // Check if any data exists (since sample data is the only data that should be present)
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        
        do {
            let count = try context.count(for: fetchRequest)
            await MainActor.run {
                hasSampleData = count > 0
            }
        } catch {
            print("Error checking sample data status: \(error)")
            await MainActor.run {
                hasSampleData = false
            }
        }
    }
    
    private func addSampleData() async {
        isProcessing = true
        
        do {
            await CoreDataStack.shared.seedSampleData()
            await MainActor.run {
                hasSampleData = true
                alertMessage = "Sample data loaded successfully!\n\nAdded:\n• 25 products across 8 categories\n• 5 shopping locations\n• 8 items to shopping list\n• 6 favorite items\n• 5 social feed entries"
                showAlert = true
            }
        } catch {
            await MainActor.run {
                alertMessage = "Error adding sample data: \(error.localizedDescription)"
                showAlert = true
            }
        }
        
        await MainActor.run {
            isProcessing = false
        }
    }
    
    private func removeSampleData() async {
        isProcessing = true
        
        do {
            await CoreDataStack.shared.clearSampleData()
            await MainActor.run {
                hasSampleData = false
                alertMessage = "Sample data removed successfully!"
                showAlert = true
            }
        } catch {
            await MainActor.run {
                alertMessage = "Error removing sample data: \(error.localizedDescription)"
                showAlert = true
            }
        }
        
        await MainActor.run {
            isProcessing = false
        }
    }
}
