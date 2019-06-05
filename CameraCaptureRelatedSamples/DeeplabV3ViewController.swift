//
//  ViewController.swift
//  CameraCaptureRelatedSamples
//
//  Created by Yuichi Fujiki on 6/5/19.
//  Copyright © 2019 Yuichi Fujiki. All rights reserved.
//

import UIKit

class DeeplabV3ViewController: UIViewController {

    @IBOutlet weak var captureView: CameraCaptureView!

    override func viewDidLoad() {
        super.viewDidLoad()

        captureView.prepareCapture()
        captureView.startCapture()
    }

    deinit {
        captureView.endCapture()
    }
}

