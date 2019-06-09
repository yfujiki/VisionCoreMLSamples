//
//  VisionCoreMLProtocol.swift
//  VisionCoreMLSamples
//
//  Created by Yuichi Fujiki on 6/9/19.
//  Copyright © 2019 Yuichi Fujiki. All rights reserved.
//

import Foundation
import Vision

protocol VisionCoreMLProtocol {
    func visionModel() -> VNCoreMLModel?
    func visionModelRequest() -> VNCoreMLRequest?
}
