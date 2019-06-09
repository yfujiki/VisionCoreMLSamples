//
//  YoloV3ViewController.swift
//  VisionCoreMLSamples
//
//  Created by Yuichi Fujiki on 6/9/19.
//  Copyright © 2019 Yuichi Fujiki. All rights reserved.
//

import UIKit
import Vision
import AVFoundation
import CoreVideo

class YoloV3ViewController: ViewController, VisionCoreMLProtocol {

    var bufferSize: CGSize = .zero

    private var rootLayer: CALayer?
    private var detectionOverlay: CALayer?

    private var _visionModel: VNCoreMLModel?
    private var _visionModelRequest: VNCoreMLRequest?

    func visionModel() -> VNCoreMLModel? {
        if _visionModel == nil {
            //  _visionModel = try? VNCoreMLModel(for: YOLOv3().model)     // Not included in the repo. Please download from https://developer.apple.com/machine-learning/models/ to use
            //  _visionModel = try? VNCoreMLModel(for: YOLOv3FP16().model) // Not included in the repo. Please download from https://developer.apple.com/machine-learning/models/ to use
            _visionModel = try? VNCoreMLModel(for: YOLOv3Int8LUT().model)
        }
        return _visionModel
    }

    func visionModelRequest() -> VNCoreMLRequest? {
        if _visionModelRequest == nil {
            guard let visionModel = visionModel() else {
                return nil
            }

            let request = VNCoreMLRequest(model: visionModel) { [weak self] (vnRequest, error) in
                if let results = vnRequest.results as? [VNRecognizedObjectObservation] {
                    DispatchQueue.main.async {
                        self?.drawVisionRequestResults(results)
                    }
                }
            }
            request.imageCropAndScaleOption = .centerCrop

            _visionModelRequest = request
        }
        return _visionModelRequest
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupLayers()
    }

    func setupLayers() {
        rootLayer = cameraPreviewView.layer

        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay!.name = "DetectionOverlay"
        detectionOverlay!.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: rootLayer!.bounds.width,
                                         height: rootLayer!.bounds.height)
        detectionOverlay!.position = CGPoint(x: rootLayer!.bounds.midX, y: rootLayer!.bounds.midY)

        rootLayer?.addSublayer(detectionOverlay!)
    }

    private func drawVisionRequestResults(_ results: [VNRecognizedObjectObservation]) {
        let bufferRatio = bufferSize.height / bufferSize.width

        let displayWidth = rootLayer!.bounds.width
        let displayHeight = rootLayer!.bounds.height
        let i_displayWidth = Int(displayWidth)
        let i_displayHeight = Int(displayHeight)
        let displayRatio = displayHeight / displayWidth

        var i_outputWidth: Int = 0
        var i_outputHeight: Int = 0
        var xDisplayOffset: CGFloat = 0
        var yDisplayOffset: CGFloat = 0
        if (displayRatio > bufferRatio) {
            i_outputWidth = i_displayWidth
            i_outputHeight = Int(displayWidth * bufferRatio)
            yDisplayOffset = CGFloat((i_displayHeight - i_outputHeight) / 2)
        } else {
            i_outputHeight = i_displayHeight
            i_outputWidth = Int(displayHeight / bufferRatio)
            xDisplayOffset = CGFloat((i_displayWidth - i_outputWidth) / 2)
        }
        let i_outputSize = min(i_outputWidth, i_outputHeight)

        let xOutputOffset = CGFloat((i_outputWidth - i_outputSize) / 2)
        let yOutputOffset = CGFloat((i_outputHeight - i_outputSize) / 2)

        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay?.sublayers = nil // remove all the old recognized objects

        for observation in results {
            // Select only the label with the highest confidence.
            let topLabelObservation = observation.labels[0]

            var objectBounds = VNImageRectForNormalizedRect(observation.boundingBox, i_outputSize, i_outputSize)
            objectBounds.origin.y = CGFloat(i_outputSize) - objectBounds.origin.y - objectBounds.size.height

            // TODO:
            // Theoretically, we should add outputOffset as well, I think.
            // Not sure why I need to adjust y offset by 44. Will punt on it for now.
            objectBounds.origin.x += xOutputOffset + xDisplayOffset
            objectBounds.origin.y += yOutputOffset + yDisplayOffset - 44

            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)

            let textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                            identifier: topLabelObservation.identifier,
                                                            confidence: topLabelObservation.confidence)
            shapeLayer.addSublayer(textLayer)
            detectionOverlay?.addSublayer(shapeLayer)
        }
        
        CATransaction.commit()
    }

    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)\nConfidence:  %.2f", confidence))
        let largeFont = UIFont(name: "Helvetica", size: 20.0)!
        let mediumFont = UIFont(name: "Helvetica", size: 12.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: identifier.count))
        formattedString.addAttributes([NSAttributedString.Key.font: mediumFont], range: NSRange(location: identifier.count, length: formattedString.string.count - identifier.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = UIScreen.main.scale
        return textLayer
    }

    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
}

extension YoloV3ViewController {
    override func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from: AVCaptureConnection) {
        guard let cvImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        cameraPreviewView.syncedCurrentBuffer = cvImageBuffer
        bufferSize = CGSize(width: CVPixelBufferGetWidth(cvImageBuffer), height: CVPixelBufferGetHeight(cvImageBuffer))

        let handler = VNImageRequestHandler(cvPixelBuffer: cvImageBuffer)

        guard let request = visionModelRequest() else {
            return
        }

        DispatchQueue.global(qos: .userInteractive).async {
            try? handler.perform([request])
        }
    }
}

