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

class PreviewViewController: ViewController {
}

extension PreviewViewController { // AVCaptureVideoDataOutputSampleBufferDelegate
    override func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from: AVCaptureConnection) {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        cameraPreviewView.syncedCurrentBuffer = imageBuffer
    }
}
