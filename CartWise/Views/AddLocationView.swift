//
//  AddLocationView.swift
//  CartWise
//
//  Created by AI Assistant on 12/19/24.
//
import SwiftUI
import CoreData
struct AddLocationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var productViewModel: ProductViewModel
    @State private var name: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var favorited: Bool = false
    @State private var isDefault: Bool = false
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppColors.backgroundSecondary
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.accentGreen)
                            Text("Add New Location")
                                .font(.poppins(size: 24, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            Text("Save your favorite shopping locations")
                                .font(.poppins(size: 16, weight: .regular))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        // Form
                        VStack(spacing: 20) {
                            // Location Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Location Name")
                                    .font(.poppins(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                TextField("e.g., Home, Work, Mom's House", text: $name)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            // Address
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Street Address")
                                    .font(.poppins(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                TextField("123 Main Street", text: $address)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            // City, State, Zip Row
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("City")
                                        .font(.poppins(size: 16, weight: .semibold))
                                        .foregroundColor(AppColors.textPrimary)
                                    TextField("City", text: $city)
                                        .textFieldStyle(CustomTextFieldStyle())
                                }
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("State")
                                        .font(.poppins(size: 16, weight: .semibold))
                                        .foregroundColor(AppColors.textPrimary)
                                    TextField("State", text: $state)
                                        .textFieldStyle(CustomTextFieldStyle())
                                }
                            }
                            // Zip Code
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Zip Code")
                                    .font(.poppins(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                TextField("12345", text: $zipCode)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }
                            // Toggle Options
                            VStack(spacing: 16) {
                                Toggle(isOn: $favorited) {
                                    HStack {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(.red)
                                        Text("Mark as Favorite")
                                            .font(.poppins(size: 16, weight: .medium))
                                            .foregroundColor(AppColors.textPrimary)
                                    }
                                }
                                .toggleStyle(CustomToggleStyle())
                                Toggle(isOn: $isDefault) {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text("Set as Default Location")
                                            .font(.poppins(size: 16, weight: .medium))
                                            .foregroundColor(AppColors.textPrimary)
                                    }
                                }
                                .toggleStyle(CustomToggleStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        // Save Button
                        Button(action: saveLocation) {
                            HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18, weight: .medium))
                                }
                                Text(isLoading ? "Saving..." : "Save Location")
                                    .font(.poppins(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                AppColors.accentGreen,
                                                AppColors.accentGreen.opacity(0.8)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: AppColors.accentGreen.opacity(0.3), radius: 12, x: 0, y: 6)
                            )
                        }
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.6)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accentGreen)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !zipCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private func saveLocation() {
        guard isFormValid else { return }
        isLoading = true
        Task {
            do {
                // Get current user
                let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \UserEntity.createdAt, ascending: false)]
                fetchRequest.fetchLimit = 1
                let users = try viewContext.fetch(fetchRequest)
                guard let currentUser = users.first else {
                    throw LocationError.noUserFound
                }
                // If setting as default, unset other defaults
                if isDefault {
                    let locationFetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
                    locationFetchRequest.predicate = NSPredicate(format: "user == %@ AND isDefault == YES", currentUser)
                    let existingDefaults = try viewContext.fetch(locationFetchRequest)
                    for existingDefault in existingDefaults {
                        existingDefault.isDefault = false
                    }
                }
                // Create new location
                let location = Location(
                    context: viewContext,
                    id: UUID().uuidString,
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    address: address.trimmingCharacters(in: .whitespacesAndNewlines),
                    city: city.trimmingCharacters(in: .whitespacesAndNewlines),
                    state: state.trimmingCharacters(in: .whitespacesAndNewlines),
                    zipCode: zipCode.trimmingCharacters(in: .whitespacesAndNewlines),
                    favorited: favorited,
                    isDefault: isDefault
                )
                location.user = currentUser
                try viewContext.save()
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}
// MARK: - Custom Styles
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .font(.poppins(size: 16, weight: .regular))
    }
}
struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 20)
                .fill(configuration.isOn ? AppColors.accentGreen : Color.gray.opacity(0.3))
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}
// MARK: - Error Types
enum LocationError: Error, LocalizedError {
    case noUserFound
    var errorDescription: String? {
        switch self {
        case .noUserFound:
            return "No user found. Please log in again."
        }
    }
}
