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
    
    private  let newCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collection = UICollectionView(frame: CGRect(x: 0, y: 0, width: 200, height: 100), collectionViewLayout: layout)
        layout.scrollDirection = .horizontal
        collection.backgroundColor = UIColor.gray
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.isScrollEnabled = true
        return collection
    }()
    
    private var collectionNode : SCNNode?
    
    private let cellId = "NewCVC"
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setupCollectionViewNode()
        
        //Set view's delegate
        arscnView.delegate = self
        
        // show statistics such as fps & timing
        arscnView.showsStatistics = true
        

        
        let scene = SCNScene()
        
      
        //setting Sceneview Scene
        arscnView.scene = scene
        

        
    }
    
    private func setupCollectionViewNode(){
        
        newCollection.register(NewCVC.self, forCellWithReuseIdentifier: cellId)
        newCollection.delegate = self
        newCollection.dataSource = self
  
         DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
        let collectionPlane = SCNPlane(width: 0.2, height: 0.1)
        collectionPlane.firstMaterial?.diffuse.contents = self.newCollection

         self.collectionNode = SCNNode(geometry: collectionPlane)
        
        //collectionNode.eulerAngles.x = -.pi/2
        
       // collectionNode?.runAction(SCNAction.moveBy(x: 0, y: 0, z: 0, duration: 0))

        self.collectionNode?.position = SCNVector3(x: 0, y: 0.5, z: 0)
        
        }
       // node.addChildNode(collectionNode)
        
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


//MARK:- CollectionView
extension ViewController : UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 7
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = newCollection.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! NewCVC
        cell.backgroundColor = .blue
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
       return UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
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
                
                guard let cN = collectionNode  else {return }
             
                    lipstickModel.addChildNode(cN)
               
                
            }
            else{
                print("WTH man")
            }

        }

    }

}
