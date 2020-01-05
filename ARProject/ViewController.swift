//
//  ViewController.swift
//  ARProject
//
//  Created by Mojave on 05/01/20.
//  Copyright © 2020 Mojave. All rights reserved.
//

import UIKit
import ARKit
final class ViewController: UIViewController {

    @IBOutlet weak var arscnView: ARSCNView!
    
    // for ARPlane
    private var planeGeometry : SCNPlane!
    

    
    // for storing all records of ARArchors
    private var anchors = [ARAnchor]()
    
    private var lipstickModel : SCNNode?
    

    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        

        
        //Set view's delegate
        arscnView.delegate = self
        
        // show statistics such as fps & timing
        arscnView.showsStatistics = true
        

        
        let scene = SCNScene()
        
      
        //setting Sceneview Scene
        arscnView.scene = scene
        

        
    }
    
 

    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(true)
        
        // Create a Session Configuration
        let configuration = ARWorldTrackingConfiguration()
        
        //for plane detection
        configuration.planeDetection = .horizontal
        
        // for light estimation
        configuration.isLightEstimationEnabled = true
        
        //run the view's session
        arscnView.session.run(configuration)
        //   sceneView.session.run(configuration, options: .resetTracking)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        arscnView.session.pause()
    }

    
    
    
}



//MARK:- AR
extension ViewController : ARSCNViewDelegate{

    // called when we are finding an anchor or ARKit finds an anchor  (i.e. when a new plane is detected an new anchor is added)
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
       // print("found new anchor")
        var node : SCNNode?
        
        // checking is found anchor is an ARPlane Anchor
        if let planeAnchor = anchor as? ARPlaneAnchor,anchors.isEmpty{
            
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                
                //setting an SCNNode()
                node = SCNNode()
                
                // creating an Plane (extent == > length) //cmd+extent for summary
                self.planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
                
                // apply a color to Plane
                self.planeGeometry.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(CGFloat(0.5))
                
                //creating a Planenode with Planegeometry
                let planeNode = SCNNode(geometry: self.planeGeometry)
                
                // since we are using scenekit here for plane our plane is vertical we declare y=0 and will rotate the planeNode around x axis with 90 degree
                planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
                
                
                //MARK:- Rotating a Plane x =1 as we wan to rotate only x
                planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
                
                self.addLipStick(parentNode: planeNode)
                
                //adding planeNode to node
                node?.addChildNode(planeNode)
                
                // appending found anchor to list of anchor
                self.anchors.append(planeAnchor)
            }

        }
        return node
    }
    
    private func videoNode() -> SCNNode{
                //find our video file
         let videoNode = SKVideoNode(fileNamed: "black.mp4")
         videoNode.play()
         // set the size (just a rough one will do)
         let videoScene = SKScene(size: CGSize(width: 640, height: 360))
         // center our video to the size of our video scene
         videoNode.position = CGPoint(x: videoScene.size.width / 2, y: videoScene.size.height / 2)
         // invert our video so it does not look upside down
         videoNode.yScale = -1.0
         // add the video to our scene
         videoScene.addChild(videoNode)
         // create a plan that has the same real world height and width as our detected image
         let plane = SCNPlane(width: 0.2, height: 0.1)
         // set the first materials content to be our video scene
         plane.firstMaterial?.diffuse.contents = videoScene
         // create a node out of the plane
         let planeNode = SCNNode(geometry: plane)
        
          planeNode.position = SCNVector3(x: 0, y: 0.2, z: 0)
         // since the created node will be vertical, rotate it along the x axis to have it be horizontal or parallel to our detected image
        // planeNode.eulerAngles.x = Float.pi / 2
         // finally add the plane node (which contains the video node) to the added node
        // node.addChildNode(planeNode)
         return planeNode
     }
    
    private func addLipStick(parentNode : SCNNode){
        
        guard let lipstickModel = loadModel(modelName: "lipsticks2.dae") else {return}
        
        lipstickModel.transform = SCNMatrix4MakeRotation(Float.pi / 2, 1, 0, 0)
        
        lipstickModel.name = "Lipstick"
        
        self.lipstickModel = lipstickModel
        
        parentNode.addChildNode(lipstickModel)
        
    }
    
    
    private func loadModel(modelName : String) -> SCNNode?{
        
        
        guard let virtualObjectScene = SCNScene(named: modelName) else {return nil}
        
        let wrapperNode = SCNNode()
        
        for child in virtualObjectScene.rootNode.childNodes{
            wrapperNode.addChildNode(child)
        }
        
        return wrapperNode
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        if(touch.view == self.arscnView){
            print("touch working")
            let viewTouchLocation:CGPoint = touch.location(in: arscnView)
            guard let result = arscnView.hitTest(viewTouchLocation, options: nil).first else {
                return
            }
            if let lipstickModel = lipstickModel, lipstickModel.name == result.node.name {
                
                print("match")

               lipstickModel.addChildNode(videoNode())
                
            }
            else{
                print("WTH man")
            }

        }

    }

}
