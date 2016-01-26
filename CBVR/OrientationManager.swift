//
//  OrientationManager.swift
//  CBVR
//
//  Created by Michael Kent on 1/24/16.
//  Copyright © 2016 Michael Kent. All rights reserved.
//

import CoreMotion
import CoreGraphics

typealias OrientationManagerUpdateCallback = (roll: CGFloat, pitch: CGFloat, yaw: CGFloat) -> Void

class OrientationManager: NSObject {
    
    private let motionManager = CMMotionManager()
    var callback: OrientationManagerUpdateCallback
    
    init(withCallback callback: OrientationManagerUpdateCallback) {
        self.callback = callback
        super.init()
        motionManager.startDeviceMotionUpdatesUsingReferenceFrame(.XArbitraryCorrectedZVertical, toQueue: NSOperationQueue.mainQueue()) {
            (deviceMotion, error) -> Void in
            if let attitude = deviceMotion?.attitude {
                self.callback(roll: CGFloat(-attitude.pitch),
                              pitch: CGFloat(-attitude.roll - M_PI_2),
                              yaw: CGFloat(attitude.yaw))
            }
        }
    }
}
