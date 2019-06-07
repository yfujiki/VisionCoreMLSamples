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
import CoreVideo
import CoreFoundation

class DeeplabV3ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

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

    private lazy var visionModel: VNCoreMLModel? = {
        let model = try? VNCoreMLModel(for: DeepLabV3().model)
        return model
    }()

    private lazy var visionModelRequest: VNCoreMLRequest? = {
        guard let visionModel = visionModel else {
            return nil
        }

        let request = VNCoreMLRequest(model: visionModel) { [weak self] (vnRequest, error) in
            if let results = vnRequest.results as? [VNCoreMLFeatureValueObservation],
               let bestResult = results.first,
               let data = bestResult.featureValue.multiArrayValue {
                self?.showDataAsOverlay(data)
            }
        }
        request.imageCropAndScaleOption = .centerCrop

        return request
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

    private func showDataAsOverlay(_ array: MLMultiArray) {
        let width = array.strides.first!.intValue
        let height = array.count / width

        let resultPtr = UnsafeMutablePointer<Int32>(OpaquePointer(array.dataPointer))
        var data = [UInt8]()

        for i in 0..<width {
            for j in 0..<height {
                data.append(UInt8(255))
                data.append(UInt8(0))
                data.append(UInt8(0))
                data.append(UInt8(resultPtr[i + j * width]))
            }
        }

        guard let cgImage = RGBAImageViaCGImage(data: data, width: width, height: height) else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.imageView.image = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .leftMirrored)
        }
    }

    func RGBAImageViaCGImage(data: [UInt8], width: Int, height: Int) -> CGImage? {

        let bitsPerComponent = 8
        let numberOfComponents = 4
        let bitsPerPixel = bitsPerComponent * numberOfComponents

        guard width > 0, height > 0 else { return nil }
        guard width * height * numberOfComponents == data.count else { return nil }

        let rgbData = CFDataCreate(nil, data, numberOfComponents * width * height)!
        let provider = CGDataProvider(data: rgbData)!
        let image = CGImage(width: width,
                            height: height,
                            bitsPerComponent: bitsPerComponent,
                            bitsPerPixel: bitsPerPixel,
                            bytesPerRow: width * numberOfComponents,
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                            provider: provider,
                            decode: nil,
                            shouldInterpolate: true,
                            intent: CGColorRenderingIntent.defaultIntent)!
        return image
    }
}

extension DeeplabV3ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from: AVCaptureConnection) {
        guard let cvImage = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        cameraPreviewView.syncedCurrentBuffer = cvImage

        let handler = VNImageRequestHandler(cvPixelBuffer: cvImage)

        guard let request = visionModelRequest else {
            return
        }

        DispatchQueue.global(qos: .userInteractive).async {
            try? handler.perform([request])
        }
    }
}

