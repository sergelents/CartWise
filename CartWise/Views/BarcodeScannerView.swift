//
//  BarcodeScannerView.swift
//  CartWise
//
//  Created by AI Assistant on 12/19/25.
//

import SwiftUI
import AVFoundation
import UIKit

struct BarcodeScannerView: View {
    @StateObject private var scannerViewModel = BarcodeScannerViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingProductDetail = false
    @State private var scannedProduct: GroceryItem?
    
    var body: some View {
        ZStack {
            // Camera view
            CameraView(scannerViewModel: scannerViewModel)
                .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                // Top bar
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    
                    Spacer()
                    
                    Text("Scan Barcode")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Flash") {
                        scannerViewModel.toggleFlash()
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                .background(Color.black.opacity(0.5))
                
                Spacer()
                
                // Scanning frame
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 250, height: 150)
                    .background(Color.clear)
                
                Spacer()
                
                // Bottom info
                VStack(spacing: 16) {
                    Text("Position barcode within the frame")
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    if scannerViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    }
                    
                    if let errorMessage = scannerViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            scannerViewModel.startScanning()
        }
        .onDisappear {
            scannerViewModel.stopScanning()
        }
        .onChange(of: scannerViewModel.scannedBarcode) { barcode in
            if let barcode = barcode {
                handleScannedBarcode(barcode)
            }
        }
        .sheet(isPresented: $showingProductDetail) {
            if let product = scannedProduct {
                ScannedProductDetailView(product: product)
            }
        }
    }
    
    private func handleScannedBarcode(_ barcode: String) {
        Task {
            await scannerViewModel.fetchProductInfo(barcode: barcode)
            
            await MainActor.run {
                if let product = scannerViewModel.scannedProduct {
                    self.scannedProduct = product
                    self.showingProductDetail = true
                }
            }
        }
    }
}

// Camera view using UIKit
struct CameraView: UIViewRepresentable {
    @ObservedObject var scannerViewModel: BarcodeScannerViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        scannerViewModel.setupCamera(on: view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Updates handled by the view model
    }
}

// Barcode Scanner View Model
@MainActor
class BarcodeScannerViewModel: NSObject, ObservableObject {
    @Published var scannedBarcode: String?
    @Published var scannedProduct: GroceryItem?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let repository: ProductRepositoryProtocol
    
    override init() {
        self.repository = ProductRepository(coreDataContainer: CoreDataContainer())
    }
    
    func startScanning() {
        scannedBarcode = nil
        scannedProduct = nil
        errorMessage = nil
        isLoading = false
    }
    
    func stopScanning() {
        captureSession?.stopRunning()
    }
    
    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            try device.lockForConfiguration()
            if device.hasTorch {
                device.torchMode = device.torchMode == .on ? .off : .on
            }
            device.unlockForConfiguration()
        } catch {
            print("Error toggling flash: \(error)")
        }
    }
    
    func setupCamera(on view: UIView) {
        let session = AVCaptureSession()
        self.captureSession = session
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            errorMessage = "Camera not available"
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            errorMessage = "Failed to access camera"
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            errorMessage = "Failed to add camera input"
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce, .code128, .code39]
        } else {
            errorMessage = "Failed to add metadata output"
            return
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    func fetchProductInfo(barcode: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // First try to fetch from Open Food Facts API
            if let product = try await repository.fetchProductFromOpenFoodFacts(barcode: barcode) {
                await MainActor.run {
                    self.scannedProduct = product
                    self.isLoading = false
                }
                return
            }
            
            // If not found in Open Food Facts, try the existing API
            if let product = try await repository.fetchProductFromNetwork(by: barcode) {
                await MainActor.run {
                    self.scannedProduct = product
                    self.isLoading = false
                }
                return
            }
            
            // If still not found, create a basic product
            let id = UUID().uuidString
            let basicProduct = try await repository.createProduct(
                id: id,
                productName: "Product (Barcode: \(barcode))",
                brand: nil,
                category: nil,
                price: 0.0,
                currency: "USD",
                store: nil,
                location: nil,
                imageURL: nil,
                barcode: barcode
            )
            
            await MainActor.run {
                self.scannedProduct = basicProduct
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch product information: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension BarcodeScannerViewModel: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            // Stop scanning after successful scan
            captureSession?.stopRunning()
            
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            scannedBarcode = stringValue
        }
    }
}

// Product Detail View for scanned items
struct ScannedProductDetailView: View {
    let product: GroceryItem
    @Environment(\.dismiss) private var dismiss
    @StateObject private var productViewModel: ProductViewModel
    @State private var showingSuccessMessage = false
    @State private var showingDuplicateMessage = false
    
    init(product: GroceryItem) {
        self.product = product
        self._productViewModel = StateObject(wrappedValue: ProductViewModel(repository: ProductRepository(coreDataContainer: CoreDataContainer())))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Product Image
                    if let imageURL = product.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .cornerRadius(12)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 200)
                                .cornerRadius(12)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                )
                        }
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .cornerRadius(12)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Product Name
                        Text(product.productName ?? "Unknown Product")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Brand
                        if let brand = product.brand {
                            HStack {
                                Text("Brand:")
                                    .fontWeight(.semibold)
                                Text(brand)
                            }
                        }
                        
                        // Category
                        if let category = product.category {
                            HStack {
                                Text("Category:")
                                    .fontWeight(.semibold)
                                Text(category)
                            }
                        }
                        
                        // Price
                        if product.price > 0 {
                            HStack {
                                Text("Price:")
                                    .fontWeight(.semibold)
                                Text("\(product.currency ?? "USD") \(String(format: "%.2f", product.price))")
                            }
                        }
                        
                        // Store
                        if let store = product.store {
                            HStack {
                                Text("Store:")
                                    .fontWeight(.semibold)
                                Text(store)
                            }
                        }
                        
                        // Barcode
                        if let barcode = product.barcode {
                            HStack {
                                Text("Barcode:")
                                    .fontWeight(.semibold)
                                Text(barcode)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Add to Shopping List Button
                    Button(action: addToShoppingList) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add to Shopping List")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Added to Shopping List!", isPresented: $showingSuccessMessage) {
            Button("OK") { }
        } message: {
            Text("\(product.productName ?? "Product") has been added to your shopping list.")
        }
        .alert("Already in Shopping List", isPresented: $showingDuplicateMessage) {
            Button("OK") { }
        } message: {
            Text("\(product.productName ?? "Product") is already in your shopping list.")
        }
    }
    
    private func addToShoppingList() {
        Task {
            // Check if product already exists in shopping list
            let isDuplicate = await productViewModel.isDuplicateProduct(name: product.productName ?? "")
            
            if isDuplicate {
                await MainActor.run {
                    showingDuplicateMessage = true
                }
            } else {
                // Add to shopping list
                await productViewModel.addExistingProductToShoppingList(product)
                
                await MainActor.run {
                    showingSuccessMessage = true
                }
            }
        }
    }
} 
