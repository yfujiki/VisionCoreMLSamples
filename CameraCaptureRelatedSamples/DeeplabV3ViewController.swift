//
//  ViewController.swift
//  CameraCaptureRelatedSamples
//
//  Created by Yuichi Fujiki on 6/5/19.
//  Copyright © 2019 Yuichi Fujiki. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class DeeplabV3ViewController: UIViewController {

    @IBOutlet weak var captureView: CameraCaptureView!

    private lazy var visionModel: VNCoreMLModel? = {
        let model = try? VNCoreMLModel(for: DeepLabV3().model)
        return model
    }()

    private lazy var visionModelRequest: VNCoreMLRequest? = {
        guard let visionModel = visionModel else {
            return nil
        }

        let request = VNCoreMLRequest(model: visionModel) { (vnRequest, error) in
            if let results = vnRequest.results as? [VNCoreMLFeatureValueObservation],
               let bestResult = results.first,
               let data = bestResult.featureValue.multiArrayValue {
                let count = data.count
                let resultPtr = UnsafeMutablePointer<Int32>(OpaquePointer(data.dataPointer))
                for i in 0..<count {
                    print(resultPtr[i])
                }
                print("\n")
            }
        }
        request.imageCropAndScaleOption = .centerCrop

        return request
    }()

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
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from: AVCaptureConnection) {
        guard let cvImage = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: cvImage)

        guard let request = visionModelRequest else {
            return
        }

        DispatchQueue.global(qos: .userInteractive).async {
            try? handler.perform([request])
        }
    }
}

