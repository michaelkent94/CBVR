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

class SceneViewController: UIViewController {
    
    @IBOutlet weak var leftScnView: SCNView!
    @IBOutlet weak var rightScnView: SCNView!
    
    let cameraOrigin = SCNVector3(0, 0, 0)
    
    var orientationManager: OrientationManager!
    
    var cameraNode = StereoCameraNode()

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
        
        // Set up the SCNViews
        leftScnView.scene = scene
        leftScnView.backgroundColor = UIColor.clearColor()
        leftScnView.pointOfView = cameraNode.cameraLeft
        leftScnView.showsStatistics = true
        
        rightScnView.scene = scene
        rightScnView.backgroundColor = UIColor.clearColor()
        rightScnView.pointOfView = cameraNode.cameraRight
    }
    
    func setupLightingWithScene(scene: SCNScene) {
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(0, 10, 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
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
