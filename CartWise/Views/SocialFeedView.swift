//
//  SocialFeedView.swift
//  CartWise
//
//  Created by AI Assistant on 12/19/24.
//

import SwiftUI

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
    
    @State private var comment = ""
    @State private var rating: Int16 = 0
    @State private var selectedType = "general"
    @State private var showingTypePicker = false
    
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
                        
                        HStack {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: {
                                    rating = Int16(star)
                                }) {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .foregroundColor(star <= rating ? .orange : .gray)
                                        .font(.title2)
                                }
                            }
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
        }
    }
    
    private func postExperience() {
        viewModel.createExperience(
            comment: comment.trimmingCharacters(in: .whitespacesAndNewlines),
            rating: rating,
            type: selectedType,
            user: viewModel.getCurrentUser()
        )
        dismiss()
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
                            HStack {
                                ForEach(1...5, id: \.self) { star in
                                    Button(action: {
                                        newRating = Int16(star)
                                    }) {
                                        Image(systemName: star <= newRating ? "star.fill" : "star")
                                            .foregroundColor(star <= newRating ? .orange : .gray)
                                            .font(.title2)
                                    }
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