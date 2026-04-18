//
//  ObjectView.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 4/18/26.
//

//
//  FaceView.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 4/18/26.
//

import SwiftUI
import SceneKit

struct ObjectView : UIViewRepresentable {
    let objectNode: SCNNode
    
    func makeUIView(context: Context) -> SCNView {
        // create and add a camera to the scene
        let scene = SCNScene()
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()

        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)

        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)

        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)

        // add the object node to scene
        scene.rootNode.addChildNode(objectNode)

        // animate the 3d object
        objectNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))

        // retrieve the SCNView
        let scnView = SCNView()
        scnView.scene = scene
        scnView.allowsCameraControl = true

        // show statistics such as fps and timing information
        scnView.showsStatistics = true

        // configure the view
        scnView.backgroundColor = UIColor.black
        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        
       
    }
}

