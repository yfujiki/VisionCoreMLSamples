//
//  FCRNViewController.swift
//  VisionCoreMLSamples
//
//  Created by Yuichi Fujiki on 6/10/19.
//  Copyright © 2019 Yuichi Fujiki. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class FCRNViewController: ViewController {

    var currentPreviewBuffer: CVPixelBuffer?

    private var _visionModel: VNCoreMLModel?
    private var _visionModelRequest: VNCoreMLRequest?

    func visionModel() -> VNCoreMLModel? {
        if _visionModel == nil {
            //  _visionModel = try? VNCoreMLModel(for: FCRN().model)     // Not included in the repo. Please download from https://developer.apple.com/machine-learning/models/ to use
            _visionModel = try? VNCoreMLModel(for: FCRNFP16().model)
        }
        return _visionModel
    }

    func visionModelRequest() -> VNCoreMLRequest? {
        if _visionModelRequest == nil {
            guard let visionModel = visionModel() else {
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

            _visionModelRequest = request
        }
        return _visionModelRequest
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

        // ToDo : Calculation of the width/height is kind of random. Haven't figured out the definitive way.
        let depthWidth = array.strides[1].intValue
        let depthHeight = array.count / depthWidth

        let depthPtr = UnsafeMutablePointer<Double>(OpaquePointer(array.dataPointer))

        let widthRatio = Float(bufferWidth) / Float(depthWidth)
        let heightRatio = Float(bufferHeight) / Float(depthHeight)
        let ratio = min(widthRatio, heightRatio)

        let stretchedWidth = Int(Float(depthWidth) * ratio)
        let stretchedHeight = Int(Float(depthHeight) * ratio)

        let offsetX = (bufferWidth - stretchedWidth) / 2
        let offsetY = (bufferHeight - stretchedHeight) / 2

        for row in 0..<bufferHeight {
            var pixel = baseAddress + row * bytesPerRow
            for col in 0..<bufferWidth {
                let i = col - offsetX
                let j = row - offsetY

                if (i >= 0 && i < stretchedWidth) && (j >= 0 && j < stretchedHeight) {
                    let index = Int(Float(i) / ratio) + Int(Float(j) / ratio) * depthWidth
                    let value = UInt8(min(100 * depthPtr[index], 255))

                    let blue = pixel
                    blue.storeBytes(of: 255 - value, as: UInt8.self)

                    let red = pixel + 1
                    red.storeBytes(of: 255 - value, as: UInt8.self)

                    let green = pixel + 2
                    green.storeBytes(of: 255 - value, as: UInt8.self)
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

extension FCRNViewController {
    override func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from: AVCaptureConnection) {
        guard let cvImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        currentPreviewBuffer = cvImageBuffer

        let handler = VNImageRequestHandler(cvPixelBuffer: cvImageBuffer)

        guard let request = visionModelRequest() else {
            return
        }

        DispatchQueue.global(qos: .userInteractive).async {
            try? handler.perform([request])
        }
    }
}
