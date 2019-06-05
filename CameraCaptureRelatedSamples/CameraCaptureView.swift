//
//  CameraCaptureView.swift
//  CameraCaptureRelatedSamples
//
//  Created by Yuichi Fujiki on 6/5/19.
//  Copyright © 2019 Yuichi Fujiki. All rights reserved.
//

import UIKit
import AVFoundation

class CameraCaptureView: UIView {

    let session = AVCaptureSession()

    private lazy var cameraPreviewView: CameraPreviewView = {
        let view = CameraPreviewView()
        self.addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            view.topAnchor.constraint(equalTo: self.topAnchor),
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])

        return view
    }()

    private let sessionQueue = DispatchQueue(label: "com.yfujiki.cameracapturerelatedsamples-queue")

    func prepareCapture() {
        cameraPreviewView.session = session

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

    func startCapture() {
        session.startRunning()
    }

    func endCapture() {
        session.stopRunning()
    }

    private func prepareCaptureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            return
        }

        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
            }
        } catch (let error) {
            print("Failed with \(error)")
        }

        session.commitConfiguration()
    }
}
