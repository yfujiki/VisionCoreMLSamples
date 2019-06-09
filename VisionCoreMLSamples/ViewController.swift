//
//  ViewController.swift
//  VisionCoreMLSamples
//
//  Created by Yuichi Fujiki on 6/9/19.
//  Copyright © 2019 Yuichi Fujiki. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class ViewController: UIViewController {

//    var bufferSize: CGSize {
//        return cameraCapture.bufferSize
//    }

    lazy var cameraPreviewView: CameraPreviewView = {
        let previewView = CameraPreviewView()

        view.insertSubview(previewView, at: 0)

        previewView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            previewView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            previewView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])

        return previewView
    }()

    lazy var cameraCapture: CameraCapture = {
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

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from: AVCaptureConnection) {
        fatalError("Subclass needs to implement this")
    }
}


