//
//  CameraViewController.swift
//  CartWise
//
//  Created by Brenna Wilson on 7/12/25.
//
import UIKit
import AVFoundation
import SwiftUI
class CameraViewController: UIViewController {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isScanning = false
    var onBarcodeScanned: ((String) -> Void)?
    var onError: ((String) -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }
    private func setupCamera() {
        // Check camera permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCaptureSession()
                    } else {
                        self?.onError?("Camera access is required to scan barcodes")
                    }
                }
            }
        case .denied, .restricted:
            onError?("Camera access is required to scan barcodes. Please enable it in Settings.")
        @unknown default:
            onError?("Camera access is required to scan barcodes")
        }
    }
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        // Get the back camera
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            onError?("Unable to access camera")
            return
        }
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            onError?("Unable to initialize camera")
            return
        }
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            onError?("Unable to add camera input")
            return
        }
        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [
                .ean8,
                .ean13,
                .pdf417,
                .qr,
                .code128,
                .code39,
                .upce
            ]
        } else {
            onError?("Unable to add metadata output")
            return
        }
        // Setup preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }
        // Add scanning overlay
        addScanningOverlay()
    }
    private func addScanningOverlay() {
        let overlayView = UIView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = UIColor.clear
        view.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        // Add scanning frame
        let scanningFrame = UIView()
        scanningFrame.translatesAutoresizingMaskIntoConstraints = false
        scanningFrame.layer.borderColor = UIColor.white.cgColor
        scanningFrame.layer.borderWidth = 2.0
        scanningFrame.backgroundColor = UIColor.clear
        overlayView.addSubview(scanningFrame)
        NSLayoutConstraint.activate([
            scanningFrame.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            scanningFrame.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            scanningFrame.widthAnchor.constraint(equalToConstant: 250),
            scanningFrame.heightAnchor.constraint(equalToConstant: 150)
        ])
        // Add corner indicators
        addCornerIndicators(to: scanningFrame)
    }
    private func addCornerIndicators(to frame: UIView) {
        let cornerLength: CGFloat = 20
        let cornerThickness: CGFloat = 3
        let corners = [
            (frame.topAnchor, frame.leadingAnchor, true, true),   // Top-left
            (frame.topAnchor, frame.trailingAnchor, true, false),  // Top-right
            (frame.bottomAnchor, frame.leadingAnchor, false, true), // Bottom-left
            (frame.bottomAnchor, frame.trailingAnchor, false, false) // Bottom-right
        ]
        for (verticalAnchor, horizontalAnchor, isTop, isLeft) in corners {
            let isBottom = !isTop
            let cornerView = UIView()
            cornerView.translatesAutoresizingMaskIntoConstraints = false
            cornerView.backgroundColor = UIColor.white
            frame.addSubview(cornerView)
            if isTop {
                cornerView.topAnchor.constraint(equalTo: verticalAnchor).isActive = true
            } else {
                cornerView.bottomAnchor.constraint(equalTo: verticalAnchor).isActive = true
            }
            if isLeft {
                cornerView.leadingAnchor.constraint(equalTo: horizontalAnchor).isActive = true
            } else {
                cornerView.trailingAnchor.constraint(equalTo: horizontalAnchor).isActive = true
            }
            if isTop || isBottom {
                cornerView.widthAnchor.constraint(equalToConstant: cornerLength).isActive = true
                cornerView.heightAnchor.constraint(equalToConstant: cornerThickness).isActive = true
            } else {
                cornerView.widthAnchor.constraint(equalToConstant: cornerThickness).isActive = true
                cornerView.heightAnchor.constraint(equalToConstant: cornerLength).isActive = true
            }
        }
    }
    private func startScanning() {
        guard let captureSession = captureSession, !captureSession.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            captureSession.startRunning()
            DispatchQueue.main.async {
                self?.isScanning = true
            }
        }
    }
    private func stopScanning() {
        guard let captureSession = captureSession, captureSession.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.stopRunning()
        }
        isScanning = false
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
}
// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension CameraViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard isScanning else { return }
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            // Stop scanning to prevent multiple scans
            stopScanning()
            // Provide haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            // Call the callback
            onBarcodeScanned?(stringValue)
        }
    }
}