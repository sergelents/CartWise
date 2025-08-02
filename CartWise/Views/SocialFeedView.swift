//
//  SocialFeedView.swift
//  CartWise
//
//  Created by AI Assistant on 12/19/24.
//

import SwiftUI
import CoreData

struct SocialFeedView: View {
    @StateObject private var viewModel = SocialFeedViewModel()
    @State private var showingAddExperience = false
    @State private var selectedExperience: ShoppingExperience?
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading feed...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.experiences.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No experiences yet")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        
                        Text("Be the first to share your shopping experience!")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.experiences) { experience in
                                ExperienceCardView(experience: experience, viewModel: viewModel)
                                    .onTapGesture {
                                        selectedExperience = experience
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Social Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddExperience = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddExperience) {
                AddExperienceView(viewModel: viewModel)
            }
            .sheet(item: $selectedExperience) { experience in
                ExperienceDetailView(experience: experience, viewModel: viewModel)
            }
            .refreshable {
                viewModel.loadExperiences()
            }
        }
        .onAppear {
            viewModel.loadExperiences()
        }
    }
}

struct ExperienceCardView: View {
    let experience: ShoppingExperience
    let viewModel: SocialFeedViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(experience.user?.username ?? "Anonymous")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(viewModel.formatDate(experience.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Type badge
                Text(experience.displayType)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(typeColor.opacity(0.2))
                    .foregroundColor(typeColor)
                    .cornerRadius(8)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(experience.comment ?? "")
                    .font(.body)
                    .multilineTextAlignment(.leading)
                
                if experience.rating > 0 {
                    HStack {
                        Text(viewModel.formatRating(experience.rating))
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Spacer()
                    }
                }
                
                // Related item/location info
                if let groceryItem = experience.groceryItem {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.blue)
                        Text(groceryItem.productName ?? "Unknown Product")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                } else if let location = experience.location {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        Text(location.name ?? "Unknown Location")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Comments count
            if !experience.commentArray.isEmpty {
                HStack {
                    Image(systemName: "bubble.left")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(experience.commentArray.count) comments")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var typeColor: Color {
        switch experience.type {
        case "price_update":
            return .green
        case "store_review":
            return .orange
        case "product_review":
            return .blue
        case "general":
            return .purple
        default:
            return .gray
        }
    }
}

struct AddExperienceView: View {
    @ObservedObject var viewModel: SocialFeedViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var comment = ""
    @State private var rating: Int16 = 0
    @State private var selectedType = "general"
    @State private var showingTypePicker = false
    
    // Optional fields for additional information
    @State private var selectedProduct: GroceryItem?
    @State private var selectedLocation: Location?
    @State private var price: String = ""
    @State private var showingProductPicker = false
    @State private var showingLocationPicker = false
    
    // Available products and locations
    @State private var availableProducts: [GroceryItem] = []
    @State private var availableLocations: [Location] = []
    
    private let types = [
        ("general", "General Comment"),
        ("price_update", "Price Update"),
        ("store_review", "Store Review"),
        ("product_review", "Product Review")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Experience Details") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(types, id: \.0) { type in
                            Text(type.1).tag(type.0)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rating")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: {
                                    // If tapping the same star, clear the rating, otherwise set to the tapped star
                                    rating = rating == Int16(star) ? 0 : Int16(star)
                                }) {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .foregroundColor(star <= rating ? .orange : .gray)
                                        .font(.title2)
                                        .frame(width: 32, height: 32)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                
                // Optional Product Information
                if selectedType == "product_review" || selectedType == "price_update" {
                    Section("Product Information (Optional)") {
                        Button(action: {
                            loadAvailableProducts()
                            showingProductPicker = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Product")
                                        .font(.headline)
                                    Text(selectedProduct?.productName ?? "Select a product")
                                        .font(.subheadline)
                                        .foregroundColor(selectedProduct == nil ? .gray : .primary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if selectedProduct != nil {
                            Button("Clear Product") {
                                selectedProduct = nil
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                
                // Optional Store Information
                if selectedType == "store_review" || selectedType == "price_update" {
                    Section("Store Information (Optional)") {
                        Button(action: {
                            loadAvailableLocations()
                            showingLocationPicker = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Store")
                                        .font(.headline)
                                    Text(selectedLocation?.name ?? "Select a store")
                                        .font(.subheadline)
                                        .foregroundColor(selectedLocation == nil ? .gray : .primary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if selectedLocation != nil {
                            Button("Clear Store") {
                                selectedLocation = nil
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                
                // Optional Price Information
                if selectedType == "price_update" {
                    Section("Price Information (Optional)") {
                        HStack {
                            Text("$")
                                .font(.headline)
                                .foregroundColor(.gray)
                            TextField("0.00", text: $price)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                
                Section("Comment") {
                    TextEditor(text: $comment)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Experience")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        postExperience()
                    }
                    .disabled(comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showingProductPicker) {
                ProductPickerView(selectedProduct: $selectedProduct)
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(selectedLocation: $selectedLocation)
            }
        }
    }
    
    private func postExperience() {
        // Create enhanced comment with optional information
        var enhancedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add product information if available
        if let product = selectedProduct {
            enhancedComment += "\n\nProduct: \(product.productName ?? "Unknown")"
            if let brand = product.brand, !brand.isEmpty {
                enhancedComment += " (\(brand))"
            }
        }
        
        // Add store information if available
        if let location = selectedLocation {
            enhancedComment += "\nStore: \(location.name ?? "Unknown")"
            if let address = location.address, !address.isEmpty {
                enhancedComment += " (\(address))"
            }
        }
        
        // Add price information if available
        if !price.isEmpty, let priceValue = Double(price) {
            enhancedComment += "\nPrice: $\(String(format: "%.2f", priceValue))"
        }
        
        // Get current user from the same context
        let currentUser = viewModel.getCurrentUser()
        
        viewModel.createExperience(
            comment: enhancedComment,
            rating: rating,
            type: selectedType,
            groceryItem: selectedProduct,
            location: selectedLocation,
            user: currentUser
        )
        dismiss()
    }
    
    // MARK: - Helper Methods
    
    private func loadAvailableProducts() {
        let request: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GroceryItem.productName, ascending: true)]
        
        do {
            availableProducts = try viewContext.fetch(request)
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    private func loadAvailableLocations() {
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Location.name, ascending: true)]
        
        do {
            availableLocations = try viewContext.fetch(request)
        } catch {
            print("Failed to load locations: \(error)")
        }
    }
}

// MARK: - Product Picker View
struct ProductPickerView: View {
    @Binding var selectedProduct: GroceryItem?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var searchText = ""
    @State private var products: [GroceryItem] = []
    @State private var isLoading = true
    
    var filteredProducts: [GroceryItem] {
        if searchText.isEmpty {
            return products
        }
        return products.filter { product in
            let nameMatch = product.productName?.localizedCaseInsensitiveContains(searchText) == true
            let brandMatch = product.brand?.localizedCaseInsensitiveContains(searchText) == true
            let categoryMatch = product.category?.localizedCaseInsensitiveContains(searchText) == true
            return nameMatch || brandMatch || categoryMatch
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search products...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                .padding(.top)
                
                if isLoading {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading products...")
                            .font(.poppins(size: 14, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else if products.isEmpty {
                    // Empty State
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "cart")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("No Products Found")
                                .font(.poppins(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Add products to your shopping list first")
                                .font(.poppins(size: 14, weight: .regular))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    }
                    Spacer()
                } else {
                    // Products List
                    List {
                        ForEach(filteredProducts, id: \.id) { product in
                            Button(action: {
                                selectedProduct = product
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product.productName ?? "Unknown Product")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        if let brand = product.brand, !brand.isEmpty {
                                            Text(brand)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        if let category = product.category, !category.isEmpty {
                                            Text(category)
                                                .font(.caption)
                                                .foregroundColor(.gray.opacity(0.7))
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedProduct?.id == product.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .navigationTitle("Select Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadProducts()
            }
        }
    }
    
    private func loadProducts() {
        let request: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GroceryItem.productName, ascending: true)]
        
        do {
            products = try viewContext.fetch(request)
            isLoading = false
        } catch {
            print("Failed to load products: \(error)")
            isLoading = false
        }
    }
}

struct ExperienceDetailView: View {
    let experience: ShoppingExperience
    @ObservedObject var viewModel: SocialFeedViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var newComment = ""
    @State private var newRating: Int16 = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Main experience
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(experience.user?.username ?? "Anonymous")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text(viewModel.formatDate(experience.createdAt))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Text(experience.displayType)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                        
                        Text(experience.comment ?? "")
                            .font(.body)
                        
                        if experience.rating > 0 {
                            Text(viewModel.formatRating(experience.rating))
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Comments
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Comments (\(experience.commentArray.count))")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if experience.commentArray.isEmpty {
                            Text("No comments yet")
                                .font(.body)
                                .foregroundColor(.gray)
                                .italic()
                        } else {
                            ForEach(experience.commentArray) { comment in
                                CommentView(comment: comment, viewModel: viewModel)
                            }
                        }
                    }
                    
                    // Add comment section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add Comment")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { star in
                                    Button(action: {
                                        // If tapping the same star, clear the rating, otherwise set to the tapped star
                                        newRating = newRating == Int16(star) ? 0 : Int16(star)
                                    }) {
                                        Image(systemName: star <= newRating ? "star.fill" : "star")
                                            .foregroundColor(star <= newRating ? .orange : .gray)
                                            .font(.title2)
                                            .frame(width: 32, height: 32)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            TextField("Write a comment...", text: $newComment, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                            
                            Button("Post Comment") {
                                postComment()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Experience Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func postComment() {
        viewModel.createComment(
            comment: newComment.trimmingCharacters(in: .whitespacesAndNewlines),
            rating: newRating,
            experience: experience,
            user: viewModel.getCurrentUser()
        )
        newComment = ""
        newRating = 0
    }
}

struct CommentView: View {
    let comment: UserComment
    let viewModel: SocialFeedViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.user?.username ?? "Anonymous")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(viewModel.formatDate(comment.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(comment.comment ?? "")
                .font(.body)
            
            if comment.rating > 0 {
                Text(viewModel.formatRating(comment.rating))
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    SocialFeedView()
} 
