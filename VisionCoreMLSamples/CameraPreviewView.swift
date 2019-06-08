//
//  CameraPreviewView.swift
//  VisionCoreMLSamples
//
//  Created by Yuichi Fujiki on 6/5/19.
//  Copyright © 2019 Yuichi Fujiki. All rights reserved.
//

import UIKit
//import AVFoundation
import MetalKit

class CameraPreviewView: MTKView {
    private let syncQueue = DispatchQueue(label: "Preview View Sync Queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)

    private var currentBuffer: CVPixelBuffer?

    var syncedCurrentBuffer: CVPixelBuffer? {
        get {
            var ret: CVPixelBuffer?
            syncQueue.sync {
                ret = self.currentBuffer
            }
            return ret
        }
        set {
            syncQueue.sync {
                self.currentBuffer = newValue
            }
        }
    }

    private var textureCache: CVMetalTextureCache?

    required init(coder: NSCoder) {
        super.init(coder: coder)

        configure()
    }

    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)

        configure()
    }

    private func configure() {
        device = MTLCreateSystemDefaultDevice()

        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device!, nil, &textureCache)

        self.framebufferOnly = false
    }

    private func metalTextureFromImageBuffer(_ pixelBuffer: CVPixelBuffer) -> MTLTexture? {
        guard let textureCache = textureCache else { return nil }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        var imageTexture: CVMetalTexture?

        let _ = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &imageTexture)

        guard let metalImageTexture = imageTexture else { return nil }

        return CVMetalTextureGetTexture(metalImageTexture)
    }

    private func currentTexture() -> MTLTexture? {
        guard let pixelBuffer = syncedCurrentBuffer else { return nil }

        return metalTextureFromImageBuffer(pixelBuffer)
    }

    override func draw(_ rect: CGRect) {
        guard let drawable = currentDrawable else { return }
        guard let device = device else { return }
        guard let texture = currentTexture() else { return }

        let commandQueue = device.makeCommandQueue()
        let commandBuffer = commandQueue!.makeCommandBuffer()!

        let w = min(drawable.texture.width, texture.width)
        let h = min(drawable.texture.height, texture.height)

        let offsetX = (drawable.texture.width - texture.width) / 2
        let offsetY = (drawable.texture.height - texture.height) / 2

        let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
        blitEncoder.copy(from: texture,
                         sourceSlice: 0,
                         sourceLevel: 0,
                         sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                         sourceSize: MTLSizeMake(w, h, texture.depth),
                         to: drawable.texture,
                         destinationSlice: 0,
                         destinationLevel: 0,
                         destinationOrigin: MTLOrigin(x: offsetX, y: offsetY, z: 0))
        blitEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

