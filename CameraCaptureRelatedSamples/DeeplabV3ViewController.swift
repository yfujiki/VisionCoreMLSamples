//
//  ViewController.swift
//  CameraCaptureRelatedSamples
//
//  Created by Yuichi Fujiki on 6/5/19.
//  Copyright © 2019 Yuichi Fujiki. All rights reserved.
//

import UIKit
import AVFoundation

class DeeplabV3ViewController: UIViewController {

    @IBOutlet weak var captureView: CameraCaptureView!

    override func viewDidLoad() {
        super.viewDidLoad()

        captureView.setBufferDelegate(delegate: self)
        captureView.prepareCapture()
        captureView.startCapture()
    }

    deinit {
        captureView.endCapture()
    }
}

extension DeeplabV3ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput: CMSampleBuffer, from: AVCaptureConnection) {

    }
}

