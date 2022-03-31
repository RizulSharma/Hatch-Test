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
    
    var boxAnchor: ARAnchor?
    let boxAnchorName = "virtualObject"
    
    var virtualObject1: SCNNode = {
        
        let node1 = SCNNode()
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        box.materials = [material]
        node1.geometry = box
        return node1
    }()
    
    
    var virtualObject2: SCNNode = {
        
        let node1 = SCNNode()
        //Creating a sphere. l/b/h is in meters here.
        let sphere = SCNSphere(radius: 0.1)
        let material = SCNMaterial()
        // Used mars image just for visual enhancement.
        material.diffuse.contents = UIImage(named: "art.scnassets/8k_mars.jpeg")
        sphere.materials = [material]
        node1.geometry = sphere
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
    
    fileprivate func checkPreviousMaps() {
         FirestoreInterface.instance.readMapFromDB { isAvailable in
             if isAvailable != nil {
                 self.loadExperienceButton.isHidden = false
             } else {
                 self.loadExperienceButton.isHidden = true
             }
         }
    }

    @IBAction func handleSceneTap(_ sender: UITapGestureRecognizer) {

        // Disable placing objects when the session is still relocalizing
        if isRelocalizingMap && boxAnchor == nil {
            return
        }
        // Hit test to find a place for a virtual object.
        guard let hitTestResult = sceneView.hitTest(sender.location(in: sceneView), types: [.existingPlaneUsingExtent]).first else { return }
        
        // Remove exisitng anchor and add new anchor
        if let existingAnchor = boxAnchor {
            sceneView.session.remove(anchor: existingAnchor)
        }
        boxAnchor = ARAnchor(name: boxAnchorName, transform: hitTestResult.worldTransform)
        sceneView.session.add(anchor: boxAnchor!)
        
    }
    
    // MARK: - ARSCNViewDelegate
    
    /// - Tag: RestoreVirtualContent
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        debugPrint("didAddNode called")
        
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
            
//            self.showAlert(title: "Plane found!", message: "Press ok to add your geometries.") { _ in
//                debugPrint("Okay pressed")
//            }
        }
        guard anchor.name == boxAnchorName
            else { return }
        
        // save the reference to the virtual object anchor when the anchor is added from relocalizing
        if boxAnchor == nil {
            boxAnchor = anchor
        }
        
        node.addChildNode(virtualObject1)
        virtualObject2.position = SCNVector3(x: virtualObject1.position.x + 0.2,
                                    y: virtualObject1.position.y,
                                    z: virtualObject1.position.z)
        node.addChildNode(virtualObject2)
        
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
                boxAnchor != nil && frame.anchors.contains(boxAnchor!)
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
            if frame.anchors.contains(where: { $0.name == boxAnchorName }) {
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
    
    
    @IBAction func rotateX(_ sender: UIButton) {
        let randomX = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        virtualObject1.runAction(SCNAction.rotateBy(x: CGFloat(randomX), y: 0, z: 0, duration: 0.5))
    }
    
    @IBAction func rotateY(_ sender: UIButton) {
        let randomY = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        virtualObject1.runAction(SCNAction.rotateBy(x: 0, y: CGFloat(randomY), z: 0, duration: 0.5))
    }
    
    @IBAction func rotateZ(_ sender: UIButton) {
        let randomZ = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        virtualObject1.runAction(SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(randomZ), duration: 0.5))
    }
    
    
    @IBAction func saveExperience(_ sender: UIButton) {
        
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { self.showAlert(title: "Can't get current world map", message: error!.localizedDescription); return }
            
            // Add a snapshot image indicating where the map was captured.
            guard let snapshotAnchor = SnapshotAnchor(capturing: self.sceneView)
                else { fatalError("Can't take snapshot") }
            map.anchors.append(snapshotAnchor)
            
            let arData = ARData(worldMap: map)
            let encoder = JSONEncoder()

            do {
                let jsonData = try encoder.encode(arData)
                FirestoreInterface.instance.writeMapToDB(mapData: jsonData) { isSuccess, err in
                    if let err = err {
                        CustomToast.show(message: err.localizedDescription, controller: self)
                        return
                    }
                    debugPrint("SUCCESS saving URL")
                    DispatchQueue.main.async {
                        self.loadExperienceButton.isHidden = false
                        self.loadExperienceButton.isEnabled = true
                    }
                }
            } catch {
                CustomToast.show(message: error.localizedDescription, controller: self)
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
                self.boxAnchor = nil
            } else {
                CustomToast.show(message: "Cannot find existing Map", controller: self)
            }
        }
        
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
