//
//  VideoView.swift
//  CBVR
//
//  Created by Michael Kent on 1/24/16.
//  Copyright © 2016 Michael Kent. All rights reserved.
//

import AVFoundation
import UIKit

class VideoView: UIView {
    
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        for device in AVCaptureDevice.devices() {
            if device.hasMediaType(AVMediaTypeVideo) && device.position == .Back {
                captureDevice = device as? AVCaptureDevice
            }
        }
    }
    
    override func didMoveToSuperview() {
        if let captureDevice = captureDevice {
            do {
                try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
                try captureDevice.lockForConfiguration()
                captureDevice.videoZoomFactor = 1
                captureDevice.unlockForConfiguration()
            } catch { return }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.connection.videoOrientation = .LandscapeRight
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspect
            previewLayer.frame = CGRect(x: 0, y: 0, width: self.frame.size.width / 2, height: self.frame.size.height)
            
            let replicatorLayer = CAReplicatorLayer()
            replicatorLayer.frame = CGRect(x: 0, y: 0, width: self.frame.size.width / 2, height: self.frame.size.height)
            replicatorLayer.instanceCount = 2
            replicatorLayer.instanceTransform = CATransform3DMakeTranslation(self.frame.size.width / 2, 0, 0)
            
            replicatorLayer.addSublayer(previewLayer)
            self.layer.insertSublayer(replicatorLayer, atIndex: 0)
            
            captureSession.startRunning()
        }
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
