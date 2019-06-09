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

class TinyYoloV3ViewController: YoloV3ViewController {

    private var _visionModel: VNCoreMLModel?

    override func visionModel() -> VNCoreMLModel? {
        if _visionModel == nil {
            //  _visionModel = try? VNCoreMLModel(for: YOLOv3Tiny().model)     // Not included in the repo. Please download from https://developer.apple.com/machine-learning/models/ to use
            //  _visionModel = try? VNCoreMLModel(for: YOLOv3TinyFP16().model) // Not included in the repo. Please download from https://developer.apple.com/machine-learning/models/ to use
            _visionModel = try? VNCoreMLModel(for: YOLOv3TinyInt8LUT().model)
        }
        return _visionModel
    }
}

