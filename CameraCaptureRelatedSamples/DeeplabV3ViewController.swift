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

    @IBOutlet weak var captureView: CameraCaptureView!

    @IBOutlet weak var imageView: UIImageView!

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

    private lazy var overlayLayer: AVSampleBufferDisplayLayer = {
        let layer = AVSampleBufferDisplayLayer()
        let size = CGSize(width: 513 / UIScreen.main.scale, height: 513 / UIScreen.main.scale)
        let originX = (self.view.frame.size.width - 513 / UIScreen.main.scale) / 2
        let originY = (self.view.frame.size.height - 513 / UIScreen.main.scale) / 2

        layer.frame = CGRect(x: originX, y: originY, width: size.width, height: size.height)

        self.captureView.layer.addSublayer(layer)
//        self.view.layer.addSublayer(layer)

        return layer
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

    private func showDataAsOverlay(_ data: MLMultiArray) {
        let width = data.strides.first!.intValue
        let height = data.count / width
        let resultPtr = UnsafeMutablePointer<Int32>(OpaquePointer(data.dataPointer))
        var data = [UInt8]()


        for i in 0..<width {
            for j in 0..<height {
                data.append(UInt8(255))
                data.append(UInt8(0))
                data.append(UInt8(0))
                data.append(UInt8(resultPtr[i + j * width]))
            }
        }

        // Replace resultPtr
//        let count = 4
//        let bytesPointer = UnsafeMutableRawPointer.allocate(
//            byteCount: count * MemoryLayout<UInt8>.stride,
//            alignment: MemoryLayout<UInt8>.alignment
//        )
//
//        var values: [UInt8] = [] //[0xCC, 0xAA, 0xBB, 0xFF]
//        for _ in 0 ..< 513 * 513 {
//            values.append(0xCC as UInt8)
//            values.append(0xAA as UInt8)
//            values.append(0xBB as UInt8)
//            values.append(0xFF as UInt8)
//        }
//
//        let resultPtr: UnsafeMutablePointer<UInt8> = values.withUnsafeBufferPointer { (buffer: UnsafeBufferPointer<UInt8>) in
//            return bytesPointer.initializeMemory(
//                as: UInt8.self,
//                from: buffer.baseAddress!,
//                count: buffer.count
//            )
//        }
//         int8Pointer.pointee == 1
//         (int8Pointer + 3).pointee == 4
//         After using 'int8Pointer':
//        resultPtr.deallocate()
        // == Till Here ==

//        let pxBuffer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: 1)
//
//        CVPixelBufferCreateWithBytes(
//            kCFAllocatorDefault,
//            513,
//            513,
//            kCVPixelFormatType_32ARGB,
//            resultPtr2,
//            513 * 4,
//            nil,
//            nil,
//            nil, //[kCVPixelBufferIOSurfacePropertiesKey: [:]] as CFDictionary,
//            pxBuffer
//        )
//
//        guard let cvPixelBuffer = pxBuffer.pointee else {
//            return
//        }
//        // Show pxBuffer onto the screen
//
//        let ciImage = CIImage(cvImageBuffer: cvPixelBuffer)
//        let uiImage = UIImage(ciImage: ciImage)


        let cgImage = RGBAImage(data: data, width: 513, height: 513)!
        let uiImage = UIImage(cgImage: cgImage)
//        let uiImage = RGBAImage()
        DispatchQueue.main.async { [unowned self] in
            self.imageView.image = uiImage
        }

//        var formatDesc: CMFormatDescription? = nil
//        CMVideoFormatDescriptionCreateForImageBuffer(
//            allocator: kCFAllocatorDefault,
//            imageBuffer: cvPixelBuffer,
//            formatDescriptionOut: &formatDesc)
//
//        var sampleBuffer: CMSampleBuffer? = nil
//
//        var info = CMSampleTimingInfo()
//        info.presentationTimeStamp = .zero
//        info.duration = .invalid
//        info.decodeTimeStamp = .invalid
//
//        CMSampleBufferCreateReadyWithImageBuffer(
//            allocator: kCFAllocatorDefault,
//            imageBuffer: cvPixelBuffer,
//            formatDescription: formatDesc!,
//            sampleTiming: &info,
//            sampleBufferOut: &sampleBuffer);
//
//        guard let videoBuffer = sampleBuffer else {
//            return
//        }
//
//        overlayLayer.enqueue(videoBuffer)

//        pxBuffer.deallocate()
    }

//    func RGBAImage() -> UIImage? {
//        var data = [UInt8]()
//
//        for i in 0..<513 * 513 {
//            data.append(UInt8(0))
//            data.append(UInt8(255))
//            data.append(UInt8(0))
//            data.append(UInt8(sin(Double(i) * 0.00001 * .pi) * 127 + 127))
//        }
//
//        guard let cgImage = RGBAImage(data: data, width: 513, height: 513) else {
//            return nil
//        }
//
//        return UIImage(cgImage: cgImage)
//    }

    func RGBAImage(data: [UInt8], width: Int, height: Int) -> CGImage? {

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

        let handler = VNImageRequestHandler(cvPixelBuffer: cvImage)

        guard let request = visionModelRequest else {
            return
        }

        DispatchQueue.global(qos: .userInteractive).async {
            try? handler.perform([request])
        }
    }
}

