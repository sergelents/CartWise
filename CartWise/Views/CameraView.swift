//
//  CameraView.swift
//  CartWise
//
//  Created by Brenna Wilson on 7/12/25.
//

import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    let onBarcodeScanned: (String) -> Void
    let onError: (String) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.black
        
        let cameraViewController = CameraViewController()
        cameraViewController.onBarcodeScanned = onBarcodeScanned
        cameraViewController.onError = onError
        
        // Add camera view controller as child
        context.coordinator.cameraViewController = cameraViewController
        
        if let cameraView = cameraViewController.view {
            cameraView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(cameraView)
            
            NSLayoutConstraint.activate([
                cameraView.topAnchor.constraint(equalTo: view.topAnchor),
                cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                cameraView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var cameraViewController: CameraViewController?
    }
} 