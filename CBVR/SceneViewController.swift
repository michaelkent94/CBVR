//
//  SceneViewController
//  CBVR
//
//  Created by Michael Kent on 1/15/16.
//  Copyright (c) 2016 Michael Kent. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class SceneViewController: UIViewController, VideoViewDelegate {
    
    @IBOutlet weak var leftScnView: SCNView!
    @IBOutlet weak var rightScnView: SCNView!
    
    let cameraOrigin = SCNVector3(0, 0, 0)
    var orientationManager: OrientationManager!
    var cameraNode = StereoCameraNode()
    
    var fingerNode: SCNNode!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        setupLightingWithScene(scene)
        
        // Setup and add the camera
        cameraNode.position = cameraOrigin
        scene.rootNode.addChildNode(cameraNode)
        
        // Set the camera to rotate with the device
        orientationManager = OrientationManager {
            (roll, pitch, yaw) -> Void in
            // We want to apply yaw, roll, then pitch
            var transform = SCNMatrix4Identity
            transform = SCNMatrix4Rotate(transform, Float(pitch), 1, 0, 0)
            transform = SCNMatrix4Rotate(transform, Float(roll), 0, 0, 1)
            transform = SCNMatrix4Rotate(transform, Float(yaw), 0, 1, 0)
            self.cameraNode.transform = transform
        }
        
        // Set up the SCNViews
        leftScnView.scene = scene
        leftScnView.backgroundColor = UIColor.clearColor()
        leftScnView.pointOfView = cameraNode.cameraLeft
        leftScnView.showsStatistics = true
        rightScnView.scene = scene
        rightScnView.backgroundColor = UIColor.clearColor()
        rightScnView.pointOfView = cameraNode.cameraRight
        
        // Add a sphere, texture it as a meteor, and animate it back and forth
        let sphere = SCNSphere(radius: 1.0)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIImage(named: "art.scnassets/meteor.jpg")
        mat.normal.contents = UIImage(named: "art.scnassets/meteor-normal.jpg")
        sphere.materials = [mat]
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3(x: 0, y: 0, z: -25)
        scene.rootNode.addChildNode(sphereNode)
        let anim = CABasicAnimation(keyPath: "position.z")
        anim.byValue = 22.0
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        anim.autoreverses = true
        anim.repeatCount = Float.infinity
        anim.duration = 4.0
        sphereNode.addAnimation(anim, forKey: "motion")
        
        let fingerSphere = SCNSphere(radius: 3)
        let red = SCNMaterial()
        red.diffuse.contents = UIColor.redColor()
        fingerSphere.materials = [red]
        fingerNode = SCNNode(geometry: fingerSphere)
        fingerNode.hidden = true
        scene.rootNode.addChildNode(fingerNode)
        
        // grab the ship and rotate it
        let ship = scene.rootNode.childNodeWithName("ship", recursively: true)!
        ship.removeFromParentNode()
        
        srand(UInt32(NSDate().timeIntervalSince1970))
        
        // Create a bunch of ships
        for _ in 0..<10 {
            let shipCopy = ship.clone()
            
            let u = CGFloat(rand()) / CGFloat(RAND_MAX)
            let v = CGFloat(rand()) / CGFloat(RAND_MAX)
            
            let theta = 2 * CGFloat(M_PI) * u
            let phi = acos(2 * v - 1)
            let r = 4 as CGFloat
            
            let x = r * sin(phi) * cos(theta)
            let y = r * sin(phi) * sin(theta)
            let z = r * cos(phi)
            
            shipCopy.position = SCNVector3(x, y, z)
            let size = 0.15
            shipCopy.scale = SCNVector3(size, size, size)
            shipCopy.pivot = SCNMatrix4MakeTranslation(Float(x), 0, Float(z))
//            shipCopy.runAction(SCNAction.repeatActionForever(SCNAction.rotateByX(0, y: 2, z: 0, duration: 1)))
            scene.rootNode.addChildNode(shipCopy)
        }
        
        (view as! VideoView).delegate = self
    }
    
    func setupLightingWithScene(scene: SCNScene) {
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(0, 10, 0)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
    }
    
    func videoView(videoView: VideoView, didRecognizePoint point: CGPoint?, atDepthInDecimeters depth: CGFloat) {
        if let point = point {
            let projected = SCNVector3(point.x, point.y, 1)
            let unprojected = leftScnView.unprojectPoint(projected)
            
            let cameraToPoint = (unprojected - cameraNode.cameraLeft.position).normalized()
            let position = cameraNode.cameraLeft.position + cameraToPoint * (Float(depth) * 10.0)
            
            print("depth = \(depth)")
            
            fingerNode.position = position
            fingerNode.hidden = false
        } else {
            fingerNode.hidden = true
        }
        
    }
    
    func handleTap(gestureRecognize: UIGestureRecognizer) {
        // check what nodes are tapped
        let p = gestureRecognize.locationInView(leftScnView)
        let hitResults = leftScnView.hitTest(p, options: nil)
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result: SCNHitTestResult = hitResults[0]
            
            // get its material
            guard let material = result.node.geometry?.firstMaterial
                  else { return }
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.setAnimationDuration(0.5)
            
            // on completion - unhighlight
            SCNTransaction.setCompletionBlock {
                SCNTransaction.begin()
                SCNTransaction.setAnimationDuration(0.5)
                
                material.emission.contents = UIColor.blackColor()
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.redColor()
            
            SCNTransaction.commit()
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .LandscapeRight
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}

func -(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
    return SCNVector3(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
}

func +(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
    return SCNVector3(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
}

func *(lhs: SCNVector3, rhs: Float) -> SCNVector3 {
    return SCNVector3(x: lhs.x * rhs, y: lhs.y * rhs, z: lhs.z * rhs)
}

extension SCNVector3 {
    func normalized() -> SCNVector3 {
        let norm = sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
        return SCNVector3(x: self.x / norm, y: self.y / norm, z: self.z / norm)
    }
}
