//
//  ViewController.swift
//  VisionCoreMLSamples
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
//        let model = try? VNCoreMLModel(for: DeepLabV3().model)     // Not included in the repo. Please download from https://developer.apple.com/machine-learning/models/ to use
//        let model = try? VNCoreMLModel(for: DeepLabV3FP16().model) // Not included in the repo. Please download from https://developer.apple.com/machine-learning/models/ to use
        let model = try? VNCoreMLModel(for: DeepLabV3Int8LUT().model)
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

    private var currentPreviewBuffer: CVPixelBuffer?

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
        guard let previewBuffer = currentPreviewBuffer else {
            return
        }

        let bytesPerPixel = 4
        CVPixelBufferLockBaseAddress(previewBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let bufferWidth = Int(CVPixelBufferGetWidth(previewBuffer))
        let bufferHeight = Int(CVPixelBufferGetHeight(previewBuffer))
        let bytesPerRow = CVPixelBufferGetBytesPerRow(previewBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(previewBuffer) else {
                return
        }

        let maskWidth = array.strides.first!.intValue
        let maskHeight = array.count / maskWidth

        let maskPtr = UnsafeMutablePointer<Int32>(OpaquePointer(array.dataPointer))

        let widthRatio = Float(bufferWidth) / Float(maskWidth)
        let heightRatio = Float(bufferHeight) / Float(maskHeight)
        let ratio = min(widthRatio, heightRatio)

        let stretchedWidth = Int(Float(maskWidth) * ratio)
        let stretchedHeight = Int(Float(maskHeight) * ratio)

        let offsetX = (bufferWidth - stretchedWidth) / 2
        let offsetY = (bufferHeight - stretchedHeight) / 2

        for row in 0..<bufferHeight {
            var pixel = baseAddress + row * bytesPerRow
            for col in 0..<bufferWidth {
                let i = col - offsetX
                let j = row - offsetY

                if (i >= 0 && i < stretchedWidth) && (j >= 0 && j < stretchedHeight) {
                    let index = Int(Float(i) / ratio) + Int(Float(j) / ratio) * maskWidth
                    let value = maskPtr[index]
                    if value > 10 {
                        let blue = pixel
                        blue.storeBytes(of: 255, as: UInt8.self)

                        let red = pixel + 1
                        red.storeBytes(of: 255, as: UInt8.self)

                        let green = pixel + 2
                        green.storeBytes(of: 255, as: UInt8.self)
                    }
//                    let alpha = pixel + 3
//                    alpha.storeBytes(of: value, as: UInt8.self)
                }
                pixel += bytesPerPixel;
            }
        }

        CVPixelBufferUnlockBaseAddress(previewBuffer, CVPixelBufferLockFlags(rawValue: 0));

        cameraPreviewView.syncedCurrentBuffer = previewBuffer
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
        guard let cvImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        currentPreviewBuffer = cvImageBuffer

        let handler = VNImageRequestHandler(cvPixelBuffer: cvImageBuffer)

        guard let request = visionModelRequest else {
            return
        }

        DispatchQueue.global(qos: .userInteractive).async {
            try? handler.perform([request])
        }
    }
}

