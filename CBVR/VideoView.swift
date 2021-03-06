//
//  VideoView.swift
//  CBVR
//
//  Created by Michael Kent on 1/24/16.
//  Copyright © 2016 Michael Kent. All rights reserved.
//

import AVFoundation
import UIKit

protocol VideoViewDelegate {
    func videoView(videoView: VideoView, didRecognizePoint: CGPoint?, atDepthInDecimeters: CGFloat)
}

class VideoView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var output: AVCaptureVideoDataOutput!
    var tracker: Tracker = Tracker(colors: [Color(r: 200, g: 0, b: 0)], threshold: 100)
    var delegate: VideoViewDelegate?
    
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
            
            // create an output and attach to the capture session
            output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey: NSNumber(int: Int32(kCVPixelFormatType_32BGRA))]
            output.alwaysDiscardsLateVideoFrames = true
            let outputQueue = dispatch_queue_create("outputQueue", DISPATCH_QUEUE_SERIAL)
            output.setSampleBufferDelegate(self, queue: outputQueue)
            if captureSession.canAddOutput(output) {
                captureSession.addOutput(output)
            }
            
            captureSession.startRunning()
        }
    }
    
    
    func captureOutput(captureOutput: AVCaptureOutput, didOutputSampleBuffer sampleBuffer: CMSampleBufferRef, fromConnection connection: AVCaptureConnection) {
        let image = imageFromSampleBuffer(sampleBuffer)
        tracker.process(image: image)
        
        let offset = (self.layer.bounds.size.height - 0.75 * self.layer.bounds.size.width) / 2
        
        var center = tracker.centersByColor.values.first
        if center != nil {
            let scale = self.layer.bounds.size.width / CGFloat(CGImageGetWidth(image)) / 2
            center!.x *= scale
            center!.y *= scale
            center!.y = self.layer.bounds.size.height - center!.y
            center!.y += offset * 2
        }
        
        delegate?.videoView(self, didRecognizePoint: center, atDepthInDecimeters: tracker.depthsByColor.values.first ?? 0)
    }
    
    
    func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage {
        // get the buffer with the image data in it
        let buffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(buffer, 0) // lock the buffer
        
        // get info on the buffer
        let baseAddress = CVPixelBufferGetBaseAddress(buffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        
        // create a bitmap graphics context with the buffer data
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue).union(.ByteOrder32Little)
        let colorSpace = CGColorSpaceCreateDeviceRGB() // create a device-dependent RGB color space
        let context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, bitmapInfo.rawValue)
        
        // create a CGImage from the data in the bitmap graphics context
        let image = CGBitmapContextCreateImage(context)!
        
        CVPixelBufferUnlockBaseAddress(buffer, 0) // unlock the buffer
        return image
    }
}
