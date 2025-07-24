//
//  AddItemsView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//

import SwiftUI

struct AddItemsView: View {
    @StateObject private var productViewModel = ProductViewModel(repository: ProductRepository())
    @State private var scannedBarcode: String = ""
    @State private var manualBarcode: String = ""
    @State private var showingCamera = false
    @State private var showingManualEntry = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var isProcessing = false
    @State private var showingSuccess = false
    @State private var successMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.accentGreen)
                    
                    Text("Scan Barcode")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Point your camera at a barcode to scan")
                        .font(.body)
                        .foregroundColor(AppColors.textPrimary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Camera View
                if showingCamera {
                    ZStack {
                        CameraView(
                            onBarcodeScanned: { barcode in
                                handleBarcodeScanned(barcode)
                            },
                            onError: { error in
                                handleError(error)
                            }
                        )
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Overlay for camera instructions
                        VStack {
                            Spacer()
                            Text("Position barcode within the frame")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                                .padding(.bottom, 40)
                        }
                    }
                    .frame(height: 300)
                } else {
                    // Placeholder when camera is not showing
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.backgroundSecondary)
                        .frame(height: 300)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppColors.accentGreen)
                                Text("Tap to start scanning")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        )
                        .padding(.horizontal)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Scan Button
                    Button(action: {
                        showingCamera.toggle()
                    }) {
                        HStack {
                            Image(systemName: showingCamera ? "stop.fill" : "camera.fill")
                                .font(.system(size: 18))
                            Text(showingCamera ? "Stop Scanning" : "Start Scanning")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.accentGreen)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Manual Entry Button
                    Button(action: {
                        showingManualEntry = true
                    }) {
                        HStack {
                            Image(systemName: "keyboard")
                                .font(.system(size: 18))
                            Text("Enter Barcode Manually")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(AppColors.accentGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.accentGreen.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // Processing Indicator
                if isProcessing {
                    VStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Processing barcode...")
                            .font(.caption)
                            .foregroundColor(AppColors.textPrimary.opacity(0.7))
                    }
                    .padding(.horizontal)
                }
                
                // Success Message
                if showingSuccess {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.accentGreen)
                        Text(successMessage)
                            .font(.caption)
                            .foregroundColor(AppColors.accentGreen)
                    }
                    .padding(.horizontal)
                }
                
                // Scanned Result
                if !scannedBarcode.isEmpty && !isProcessing {
                    VStack(spacing: 8) {
                        Text("Scanned Barcode:")
                            .font(.caption)
                            .foregroundColor(AppColors.textPrimary.opacity(0.7))
                        
                        Text(scannedBarcode)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppColors.backgroundSecondary)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Add Items")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingManualEntry) {
                ManualBarcodeEntryView(
                    barcode: $manualBarcode,
                    onBarcodeEntered: { barcode in
                        handleBarcodeScanned(barcode)
                        showingManualEntry = false
                    }
                )
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    showingError = false
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private func handleBarcodeScanned(_ barcode: String) {
        scannedBarcode = barcode
        showingCamera = false
        isProcessing = true
        
        Task {
            await productViewModel.createProductByBarcode(barcode)
            
            await MainActor.run {
                isProcessing = false
                
                if let error = productViewModel.errorMessage {
                    errorMessage = error
                    showingError = true
                } else {
                    // Success - show success message and clear the scanned barcode
                    successMessage = "Product added successfully!"
                    showingSuccess = true
                    scannedBarcode = ""
                    
                    // Hide success message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        showingSuccess = false
                    }
                }
            }
        }
    }
    
    private func handleError(_ error: String) {
        errorMessage = error
        showingError = true
        showingCamera = false
    }
}

// MARK: - Manual Barcode Entry View
struct ManualBarcodeEntryView: View {
    @Binding var barcode: String
    let onBarcodeEntered: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.accentGreen)
                    
                    Text("Enter Barcode")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Type the barcode number manually")
                        .font(.body)
                        .foregroundColor(AppColors.textPrimary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Barcode Number")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    TextField("Enter barcode...", text: $barcode)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(AppColors.backgroundSecondary)
                        .cornerRadius(8)
                        .keyboardType(.numberPad)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        if !barcode.isEmpty {
                            onBarcodeEntered(barcode)
                        }
                    }) {
                        Text("Add Item")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(barcode.isEmpty ? Color.gray : AppColors.accentGreen)
                            .cornerRadius(12)
                    }
                    .disabled(barcode.isEmpty)
                    .padding(.horizontal)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.accentGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.accentGreen.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddItemsView()
}
