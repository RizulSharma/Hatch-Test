//
//  ViewController.swift
//  Hatch-Test
//
//  Created by Rizul Sharma on 30/03/22.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        createMarsNBox()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        //This will print if the current device supports world tracking or not.
        debugPrint("World tracking supported: ", ARWorldTrackingConfiguration.isSupported)
        
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    fileprivate func createMarsNBox() {
        let node1 = SCNNode()
        node1.position = SCNVector3(0, -0.1, -0.5)
        node1.geometry = self.createBox()
        
        let node2 = SCNNode()
        node2.position = SCNVector3(0.1, 0.1, -0.5)
        node2.geometry = self.createSphere()
        
        sceneView.scene.rootNode.addChildNode(node1)
        node1.addChildNode(node2)
        sceneView.autoenablesDefaultLighting = true
    }
    
    
    /// Creates a box geometry in 3dspace.
    fileprivate func createBox()-> SCNBox {
        //Creating a box. l/b/h is in meters here.
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        box.materials = [material]
        return box
    }
    
    /// Creates a box geometry in 3dspace.
    fileprivate func createSphere()-> SCNSphere {
        //Creating a sphere. l/b/h is in meters here.
        let sphere = SCNSphere(radius: 0.2)
        let material = SCNMaterial()
        // Used mars image just for visual enhancement.
        material.diffuse.contents = UIImage(named: "art.scnassets/8k_mars.jpeg")
        sphere.materials = [material]
        return sphere
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            debugPrint("Plane detected")
            let planeAnchor = anchor as! ARPlaneAnchor
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            let planeNode = SCNNode()
            planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
            let gridMaterial = SCNMaterial()
            gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
            plane.materials = [gridMaterial]
            planeNode.geometry = plane
            node.addChildNode(planeNode)
        } else {
            return
        }
    }

}
