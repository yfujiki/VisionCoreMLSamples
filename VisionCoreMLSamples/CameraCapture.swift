//
//  CameraCapture.swift
//  VisionCoreMLSamples
//
//  Created by Yuichi Fujiki on 6/7/19.
//  Copyright © 2019 Yuichi Fujiki. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class CameraCapture {

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.yfujiki.VisionCoreMLSamples-sessionqueue")
    private let videoOutputQueue = DispatchQueue(label: "com.yfujiki.VisionCoreMLSamples-videooutputqueue")

    private lazy var videoDevice: AVCaptureDevice? = {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }()

    private lazy var captureInput: AVCaptureInput? = {
        guard let videoDevice = videoDevice else {
            return nil
        }

        return try? AVCaptureDeviceInput(device: videoDevice)
    }()

    private lazy var videoOutput: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        // This is a key when we capture output in MTL seems to accept only BGRA
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        return output
    }()

    private(set) var bufferSize: CGSize = .zero
    
    func prepareCapture() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { success in
            if !success {
                print("Failed to access video")
                return
            }
            self.sessionQueue.resume()
        }

        sessionQueue.async { [weak self] in
            self?.prepareCaptureSession()
        }
    }

    private func prepareCaptureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let captureInput = captureInput else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(captureInput) {
            session.addInput(captureInput)
        } else {
            session.commitConfiguration()
        }

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)

            // We may just need to do transform ourselves
            DispatchQueue.main.sync { [unowned self] in
                switch(UIApplication.shared.statusBarOrientation) {
                case .landscapeLeft:
                    self.videoOutput.connection(with: .video)?.videoOrientation = .landscapeLeft
                case .landscapeRight:
                    self.videoOutput.connection(with: .video)?.videoOrientation = .landscapeRight
                case .portrait:
                    self.videoOutput.connection(with: .video)?.videoOrientation = .portrait
                case .portraitUpsideDown:
                    self.videoOutput.connection(with: .video)?.videoOrientation = .portraitUpsideDown
                default:
                    self.videoOutput.connection(with: .video)?.videoOrientation = .portrait
                }
            }
        } else {
            session.commitConfiguration()
        }

        // Obtain buffersize
        let captureConnection = videoOutput.connection(with: .video)
        captureConnection?.isEnabled = true
        try? videoDevice?.lockForConfiguration()
        let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
        bufferSize.width = CGFloat(dimensions.width)
        bufferSize.height = CGFloat(dimensions.height)
        videoDevice!.unlockForConfiguration()

        session.commitConfiguration()
    }

    func startCapture() {
        session.startRunning()
    }

    func endCapture() {
        session.stopRunning()
    }

    func setBufferDelegate(delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        videoOutput.setSampleBufferDelegate(delegate, queue: videoOutputQueue)
    }
}
