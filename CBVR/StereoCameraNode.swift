//
//  StereoCameraNode.swift
//  CBVR
//
//  Created by Michael Kent on 1/22/16.
//  Copyright © 2016 Michael Kent. All rights reserved.
//

import SceneKit

class StereoCameraNode: SCNNode {
    
    var cameraLeft = SCNNode()
    var cameraRight = SCNNode()
    let eyeDistance: CGFloat
    
    init(eyeDistance: CGFloat = 0.065) {
        self.eyeDistance = eyeDistance
        super.init()
        
        cameraLeft.camera = SCNCamera()
        cameraLeft.position = SCNVector3(-eyeDistance / 2, 0, 0)
        cameraLeft.camera?.zNear = 0.0001
        cameraLeft.camera?.zFar = 100
        addChildNode(cameraLeft)
        
        cameraRight.camera = SCNCamera()
        cameraRight.position = SCNVector3(eyeDistance / 2, 0, 0)
        cameraRight.camera?.zNear = 0.0001
        cameraRight.camera?.zFar = 100
        addChildNode(cameraRight)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
    }

}
