//
//  ViewController.swift
//  Hatch-Test
//
//  Created by Rizul Sharma on 30/03/22.
//

import LBTATools
import SceneKit
import ARKit
import JGProgressHUD

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!

    @IBOutlet weak var loadExperienceButton: UIButton!
    @IBOutlet weak var saveExperienceButton: UIButton!
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var snapshotThumbnail: UIImageView!
    
    ///Progress heads up display used for showing network processing.
    fileprivate let progressHUD = JGProgressHUD(style: .dark)
    
    // Called opportunistically to verify that map data can be loaded from filesystem.
    var mapDataFromFile: Data? {
        return try? Data(contentsOf: mapSaveURL)
    }
    
    var defaultConfiguration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic
        return configuration
    }
    
    var nodes = [SCNNode]()

    // MARK: - Persistence: Saving and Loading
    lazy var mapSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("map.arexperience")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }()
    
    var isRelocalizingMap = false
    
    var virtualObjectAnchor: ARAnchor?
    let virtualObjectAnchorName = "virtualObject"
    
    var virtualObjects: SCNNode = {
        
        let node1 = SCNNode()
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        box.materials = [material]
        node1.geometry = box
        
//        let node2 = SCNNode()
//        //Creating a sphere. l/b/h is in meters here.
//        let sphere = SCNSphere(radius: 0.2)
//        let material2 = SCNMaterial()
////        node2.position =
//        // Used mars image just for visual enhancement.
//        material.diffuse.contents = UIImage(named: "art.scnassets/8k_mars.jpeg")
//        sphere.materials = [material2]
//        return [node1, node2]
        return node1
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]

        self.setupBindables()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Read in any already saved map to see if we can load one.
        self.checkPreviousMaps()
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }
        
        // Start the view's AR session.
        sceneView.session.delegate = self
        sceneView.session.run(defaultConfiguration)
        
        sceneView.debugOptions = [ .showFeaturePoints ]
        
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
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
    
    fileprivate func checkPreviousMaps() {
         FirestoreInterface.instance.readMapFromDB { isAvailable in
             if isAvailable != nil {
                 self.loadExperienceButton.isHidden = false
             } else {
                 self.loadExperienceButton.isHidden = true
             }
         }
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

    @IBAction func handleSceneTap(_ sender: UITapGestureRecognizer) {

        // Disable placing objects when the session is still relocalizing
        if isRelocalizingMap && virtualObjectAnchor == nil {
            return
        }
        // Hit test to find a place for a virtual object.
        guard let hitTestResult = sceneView
            .hitTest(sender.location(in: sceneView), types: [.existingPlaneUsingExtent, .estimatedHorizontalPlane])
            .first
            else { return }
        
        // Remove exisitng anchor and add new anchor
        if let existingAnchor = virtualObjectAnchor {
            sceneView.session.remove(anchor: existingAnchor)
        }
        virtualObjectAnchor = ARAnchor(name: virtualObjectAnchorName, transform: hitTestResult.worldTransform)
        sceneView.session.add(anchor: virtualObjectAnchor!)
        
    }
    
    // MARK: - ARSCNViewDelegate
    
    /// - Tag: RestoreVirtualContent
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
            
            self.showAlert(title: "Plane found!", message: "Press ok to add your geometries.") { _ in
                debugPrint("Okay pressed")
            }
            
        }
        guard anchor.name == virtualObjectAnchorName
            else { return }
        
        // save the reference to the virtual object anchor when the anchor is added from relocalizing
        if virtualObjectAnchor == nil {
            virtualObjectAnchor = anchor
        }
        
        node.addChildNode(virtualObjects)
//        virtualObjects.forEach { object in
//            node.addChildNode(object)
//        }
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    /// - Tag: CheckMappingStatus
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Enable Save button only when the mapping status is good and an object has been placed
        switch frame.worldMappingStatus {
        case .extending, .mapped:
            saveExperienceButton.isEnabled =
                virtualObjectAnchor != nil && frame.anchors.contains(virtualObjectAnchor!)
        default:
            saveExperienceButton.isEnabled = false
        }
        statusLabel.text = """
        Mapping: \(frame.worldMappingStatus.description)
        Tracking: \(frame.camera.trackingState.description)
        """
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoLabel.text = "Session interruption ended"
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
//                self.resetTracking(nil)
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        snapshotThumbnail.isHidden = true
        switch (trackingState, frame.worldMappingStatus) {
        case (.normal, .mapped),
             (.normal, .extending):
            if frame.anchors.contains(where: { $0.name == virtualObjectAnchorName }) {
                // User has placed an object in scene and the session is mapped, prompt them to save the experience
                message = "Tap 'Save Experience' to save the current map."
            } else {
                message = "Tap on the screen to place an object."
            }
            
        case (.normal, _) where mapDataFromFile != nil && !isRelocalizingMap:
            message = "Move around to map the environment or tap 'Load Experience' to load a saved experience."
            
        case (.normal, _) where mapDataFromFile == nil:
            message = "Move around to map the environment."
            
        case (.limited(.relocalizing), _) where isRelocalizingMap:
            message = "Move your device to the location shown in the image."
            snapshotThumbnail.isHidden = false
            
        default:
            message = trackingState.localizedFeedback
        }
        
        sessionInfoLabel.text = message
        sessionInfoLabel.isHidden = message.isEmpty
    }
    
    
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//
//        if let touch = touches.first {
//            let touchLocation = touch.location(in: sceneView)
//            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
//
//            if let hitResult = results.first {
//                print(hitResult)
//                let node1 = SCNNode()
//                node1.position = SCNVector3(x: hitResult.worldTransform.columns.3.x,
//                                            y: hitResult.worldTransform.columns.3.y,
//                                            z: hitResult.worldTransform.columns.3.z)
//                node1.geometry = self.createBox()
//                self.nodes.append(node1)
//                sceneView.scene.rootNode.addChildNode(node1)
//
//            }
//
//        }
//    }
    @IBAction func rotateX(_ sender: UIButton) {
//        let randomX = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
//        self.virtualObjects.forEach { node in
//            node.runAction(SCNAction.rotateBy(x: CGFloat(randomX), y: 0, z: 0, duration: 0.5))
//        }
    }
    
    @IBAction func rotateY(_ sender: UIButton) {
//        let randomY = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
//        self.virtualObjects.forEach { node in
//            node.runAction(SCNAction.rotateBy(x: 0, y: CGFloat(randomY), z: 0, duration: 0.5))
//        }

    }
    @IBAction func rotateZ(_ sender: UIButton) {
//        let randomZ = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
//        self.virtualObjects.forEach { node in
//            node.runAction(SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(randomZ), duration: 0.5))
//        }

    }
    
    @IBAction func saveExperience(_ sender: UIButton) {
        
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { self.showAlert(title: "Can't get current world map", message: error!.localizedDescription); return }
            
            // Add a snapshot image indicating where the map was captured.
            guard let snapshotAnchor = SnapshotAnchor(capturing: self.sceneView)
                else { fatalError("Can't take snapshot") }
            map.anchors.append(snapshotAnchor)
//
//            do {
//                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
//                try data.write(to: self.mapSaveURL, options: [.atomic])
//                DispatchQueue.main.async {
//                    self.loadExperienceButton.isHidden = false
//                    self.loadExperienceButton.isEnabled = true
//                }
//            } catch {
//                fatalError("Can't save map: \(error.localizedDescription)")
//            }
            
            let arData = ARData(worldMap: map)
            let encoder = JSONEncoder()

            do {
                let jsonData = try encoder.encode(arData)
                FirestoreInterface.instance.writeMapToDB(mapData: jsonData) { _ in
                    debugPrint("SUCCESS saving URL")
                    DispatchQueue.main.async {
                        self.loadExperienceButton.isHidden = false
                        self.loadExperienceButton.isEnabled = true
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    @IBAction func loadExperience(_ sender: Any) {
        
        FirestoreInterface.instance.readMapFromDB { fetchedMap in
            if let worldMap = fetchedMap {
                // Display the snapshot image stored in the world map to aid user in relocalizing.
                if let snapshotData = worldMap.snapshotAnchor?.imageData,
                    let snapshot = UIImage(data: snapshotData) {
                    self.snapshotThumbnail.image = snapshot
                } else {
                    print("No snapshot image in world map")
                }
                // Remove the snapshot anchor from the world map since we do not need it in the scene.
                worldMap.anchors.removeAll(where: { $0 is SnapshotAnchor })
                
                let configuration = self.defaultConfiguration // this app's standard world tracking settings
                configuration.initialWorldMap = worldMap
                self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

                self.isRelocalizingMap = true
                self.virtualObjectAnchor = nil
            } else {
                debugPrint("Cannot find map.")
            }
        }
        
//        /// - Tag: Read stored WorldMap
//        let worldMap: ARWorldMap = {
//            guard let data = mapDataFromFile
//                else { fatalError("Map data should already be verified to exist before Load button is enabled.") }
//            do {
//                guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
//                    else { fatalError("No ARWorldMap in archive.") }
//                return worldMap
//            } catch {
//                fatalError("Can't unarchive ARWorldMap from file data: \(error)")
//            }
//        }()
//
//        // Display the snapshot image stored in the world map to aid user in relocalizing.
//        if let snapshotData = worldMap.snapshotAnchor?.imageData,
//            let snapshot = UIImage(data: snapshotData) {
//            self.snapshotThumbnail.image = snapshot
//        } else {
//            print("No snapshot image in world map")
//        }
//        // Remove the snapshot anchor from the world map since we do not need it in the scene.
//        worldMap.anchors.removeAll(where: { $0 is SnapshotAnchor })
//
//        let configuration = self.defaultConfiguration // this app's standard world tracking settings
//        configuration.initialWorldMap = worldMap
//        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
//
//        isRelocalizingMap = true
//        virtualObjectAnchor = nil
        
    }
    
    fileprivate func setupBindables() {
        self.progressHUD.textLabel.text = "Please wait.."
        FirestoreInterface.instance.busyLD.bind { isBusy in
            if isBusy {
                self.view.endEditing(true)
                self.progressHUD.show(in: self.view)
            } else {
                self.progressHUD.dismiss(animated: true)
            }
        }
    }
    
}
