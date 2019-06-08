//
//  PreviewViewController.swift
//  VisionCoreMLSamples
//
//  Created by Yuichi Fujiki on 6/7/19.
//  Copyright © 2019 Yuichi Fujiki. All rights reserved.
//

import UIKit
import MetalKit
import AVFoundation

class PreviewViewController: UIViewController {

    private lazy var cameraPreviewView: CameraPreviewView = {
        let previewView = CameraPreviewView()
        
        view.insertSubview(previewView, at: 0)

        previewView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

        return previewView
    }()

    private lazy var cameraCapture: CameraCapture = {
        CameraCapture()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        cameraCapture.setBufferDelegate(delegate: self)
        cameraCapture.prepareCapture()
        cameraCapture.startCapture()

        _ = cameraPreviewView
    }

    deinit {
        cameraCapture.endCapture()
    }
}

extension PreviewViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from: AVCaptureConnection) {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        cameraPreviewView.syncedCurrentBuffer = imageBuffer
    }
}
