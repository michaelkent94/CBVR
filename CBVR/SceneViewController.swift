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
    
    let eyeDistance = 2.0
    let zeroParallaxDistance = 15.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        let cameras = setupCamerasWithScene(scene)
        setupLightingWithScene(scene)
        
        // retrieve the ship node
        let ship = scene.rootNode.childNodeWithName("ship", recursively: true)!
        
        // animate the 3d object
        ship.runAction(SCNAction.repeatActionForever(SCNAction.rotateByX(0, y: 2, z: 0, duration: 1)))
        
        // set the scene to the view
        leftScnView.scene = scene
        rightScnView.scene = scene
        
        // configure the view
        leftScnView.backgroundColor = UIColor.blackColor()
        rightScnView.backgroundColor = UIColor.blackColor()
        
        // Setup cameras
        leftScnView.pointOfView = cameras.left
        rightScnView.pointOfView = cameras.right
        
        leftScnView.showsStatistics = true
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: "handleTap:")
        leftScnView.addGestureRecognizer(tapGesture)
    }
    
    func setupCamerasWithScene(scene: SCNScene) -> (left: SCNNode, right: SCNNode) {
        let cameraNode = SCNNode()
        scene.rootNode.addChildNode(cameraNode)
        
        let angle = atan((eyeDistance / 2) / zeroParallaxDistance)
        
        let cameraLeft = SCNNode()
        cameraLeft.camera = SCNCamera()
        cameraLeft.position = SCNVector3(-eyeDistance / 2, 0, zeroParallaxDistance)
        cameraLeft.eulerAngles = SCNVector3(0, -angle, 0)
        cameraNode.addChildNode(cameraLeft)
        
        let cameraRight = SCNNode()
        cameraRight.camera = SCNCamera()
        cameraRight.position = SCNVector3(eyeDistance / 2, 0, zeroParallaxDistance)
        cameraRight.eulerAngles = SCNVector3(0, angle, 0)
        cameraNode.addChildNode(cameraRight)
        
        return (cameraLeft, cameraRight)
    }
    
    func setupLightingWithScene(scene: SCNScene) {
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
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
            let result: AnyObject! = hitResults[0]
            
            // get its material
            let material = result.node!.geometry!.firstMaterial!
            
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
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
