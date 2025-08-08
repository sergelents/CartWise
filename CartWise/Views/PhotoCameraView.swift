//
//  PhotoCameraView.swift
//  CartWise
//
//  Created by Kelly Yong on 8/7/25.
//  Enhanced with AI assistance from Cursor AI for camera functionality.
//
//  Camera view for taking product photos
//

import SwiftUI
import AVFoundation
import UIKit

struct PhotoCameraView: View {
    @Environment(\.dismiss) private var dismiss
    let onImageCaptured: (UIImage?) -> Void
    let showCameraSwitch: Bool
    @StateObject private var cameraController = PhotoCameraController()
    @State private var capturedImage: UIImage?
    @State private var showingConfirmation = false
    
    init(showCameraSwitch: Bool = false, onImageCaptured: @escaping (UIImage?) -> Void) {
        self.showCameraSwitch = showCameraSwitch
        self.onImageCaptured = onImageCaptured
    }
    
    var body: some View {
        if showingConfirmation, let image = capturedImage {
            // Photo confirmation view
            confirmationView(image: image)
        } else {
            // Camera view
            cameraView
        }
    }
    
    private var cameraView: some View {
        NavigationView {
            VStack(spacing: 0) {
            
            // Add some spacing above camera
            Spacer()
                .frame(height: 40)
            
            // Camera preview (no frame overlay)
            ZStack {
                // Camera preview
                CameraPreviewView(cameraController: cameraController)
                    .frame(height: 400)
                    .clipped()
                    .cornerRadius(12)
                
                // Loading overlay
                if !cameraController.isCameraReady {
                    Color.black
                        .frame(height: 400)
                        .cornerRadius(12)
                        .overlay(
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Setting up camera...")
                                    .foregroundColor(.white)
                                    .padding(.top, 20)
                            }
                        )
                }
            }
            .padding(.horizontal, 16)
            
            // Instructions
            VStack(spacing: 8) {
                Text("Position your product within the frame")
                    .font(.poppins(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.top, 16)
                
                Text("Make sure the product is well-lit and clearly visible")
                    .font(.poppins(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Bottom controls
            HStack {
                Spacer()
                
                // Capture button (green)
                Button(action: {
                    cameraController.capturePhoto { image in
                        if let image = image {
                            capturedImage = image
                            showingConfirmation = true
                        }
                    }
                }) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 60, height: 60)
                        )
                }
                .disabled(!cameraController.isCameraReady)
                
                Spacer()
            }
            .padding(.bottom, 50)
            }
            .background(Color.white)
            .navigationTitle("Take Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if showCameraSwitch {
                        Button("Switch") {
                            cameraController.switchCamera()
                        }
                    }
                }
            }
        }
        .onAppear {
            cameraController.checkPermissions()
        }
        .onDisappear {
            cameraController.cleanup()
        }
        .alert("Camera Permission Required", isPresented: $cameraController.showPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Please enable camera access in Settings to take product photos.")
        }
    }
    
    private func confirmationView(image: UIImage) -> some View {
        NavigationView {
            VStack(spacing: 0) {
            
            Spacer(minLength: 20)
            
            // Preview captured image
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 400)
                .cornerRadius(12)
                .padding(.horizontal, 16)
            
            // Instructions
            VStack(spacing: 8) {
                Text("How does your photo look?")
                    .font(.poppins(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.top, 16)
                
                Text("Use the photo for the product image or retake")
                    .font(.poppins(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Bottom controls - Use Photo and Retake
            HStack(spacing: 20) {
                // Retake button
                Button(action: {
                    showingConfirmation = false
                    capturedImage = nil
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Retake")
                    }
                    .font(.poppins(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                }
                
                // Use Photo button
                Button(action: {
                    onImageCaptured(image)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Use Photo")
                    }
                    .font(.poppins(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 80)
            }
            .background(Color.white)
            .navigationTitle("Confirm Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Camera preview view
struct CameraPreviewView: UIViewRepresentable {
    let cameraController: PhotoCameraController
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.black
        cameraController.previewView = view
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame when view bounds change
        if let previewLayer = cameraController.currentPreviewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
                // Force layout update
                uiView.setNeedsLayout()
                uiView.layoutIfNeeded()
            }
        }
    }
}

// Camera controller
class PhotoCameraController: ObservableObject {
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentCamera: AVCaptureDevice?
    
    @Published var showPermissionAlert = false
    @Published var isCameraReady = false
    
    // Photo capture delegate
    private var photoCaptureDelegate: PhotoCaptureDelegate?
    
    // Notification observers for app lifecycle
    private var foregroundObserver: NSObjectProtocol?
    private var backgroundObserver: NSObjectProtocol?
    
    init() {
        setupLifecycleObservers()
    }
    
    deinit {
        removeLifecycleObservers()
    }
    
    var previewView: UIView? {
        didSet {
            if let view = previewView {
                setupPreviewLayer(for: view)
            }
        }
    }
    
    var currentPreviewLayer: AVCaptureVideoPreviewLayer? {
        return previewLayer
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.showPermissionAlert = true
            }
        @unknown default:
            DispatchQueue.main.async {
                self.showPermissionAlert = true
            }
        }
    }
    
    private func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession = AVCaptureSession()
            guard let captureSession = self.captureSession else { return }
            
            // Configure session quality
            captureSession.sessionPreset = .photo
            
            // Get the back camera
            self.currentCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            guard let camera = self.currentCamera else {
                print("Unable to access camera")
                return
            }
            
            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                }
            } catch {
                print("Error setting up camera input: \(error)")
                return
            }
            
            // Setup photo output
            self.photoOutput = AVCapturePhotoOutput()
            if let photoOutput = self.photoOutput, captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
                print("Photo output added successfully")
            } else {
                print("Failed to add photo output")
            }
            
            captureSession.startRunning()
            
            DispatchQueue.main.async {
                self.isCameraReady = true
            }
        }
    }
    
    private func setupPreviewLayer(for view: UIView) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let captureSession = self.captureSession else { return }
            
            self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            self.previewLayer?.videoGravity = .resizeAspectFill
            self.previewLayer?.frame = view.bounds
            
            if let previewLayer = self.previewLayer {
                view.layer.addSublayer(previewLayer)
                // Force layout update
                view.setNeedsLayout()
                view.layoutIfNeeded()
            }
        }
    }
    
    func switchCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let captureSession = self.captureSession else { return }
            
            captureSession.beginConfiguration()
            
            // Remove current input
            if let currentInput = captureSession.inputs.first {
                captureSession.removeInput(currentInput)
            }
            
            // Switch camera position
            let newPosition: AVCaptureDevice.Position = self.currentCamera?.position == .back ? .front : .back
            self.currentCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition)
            
            guard let camera = self.currentCamera else { return }
            
            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                }
            } catch {
                print("Error switching camera: \(error)")
            }
            
            captureSession.commitConfiguration()
        }
    }
    
    // App lifecycle handling
    private func setupLifecycleObservers() {
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppWillEnterForeground()
        }
        
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppDidEnterBackground()
        }
    }
    
    private func removeLifecycleObservers() {
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
            foregroundObserver = nil
        }
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
            backgroundObserver = nil
        }
    }
    
    private func handleAppWillEnterForeground() {
        // Restart camera when app returns to foreground
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self,
                  let session = self.captureSession else { return }
            
            if !session.isRunning {
                print("Restarting camera session after returning to foreground")
                session.startRunning()
                
                DispatchQueue.main.async {
                    self.isCameraReady = true
                }
            }
        }
    }
    
    private func handleAppDidEnterBackground() {
        // Stop camera session when app goes to background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self,
                  let session = self.captureSession else { return }
            
            if session.isRunning {
                print("Stopping camera session as app goes to background")
                session.stopRunning()
                
                DispatchQueue.main.async {
                    self.isCameraReady = false
                }
            }
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard let photoOutput = photoOutput else {
            print("Photo output not available")
            completion(nil)
            return
        }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        settings.isAutoRedEyeReductionEnabled = true
        
        // Create and retain the delegate
        photoCaptureDelegate = PhotoCaptureDelegate(completion: completion)
        photoOutput.capturePhoto(with: settings, delegate: photoCaptureDelegate!)
    }
    
    func cleanup() {
        removeLifecycleObservers()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Check if session exists and is running before stopping
            if let session = self.captureSession, session.isRunning {
                session.stopRunning()
            }
            
            // Clean up references
            self.captureSession = nil
            self.photoOutput = nil
            self.previewLayer = nil
            self.currentCamera = nil
            self.photoCaptureDelegate = nil
        }
    }
}

// Photo capture delegate
class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let completion: (UIImage?) -> Void
    
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            completion(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Failed to create image from photo data")
            completion(nil)
            return
        }
        
        completion(image)
    }
}
