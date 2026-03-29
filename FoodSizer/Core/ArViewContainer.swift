//
//  ArViewContainer.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/22/26.
//

import SwiftUI
import ARKit
import RealityKit


@MainActor
struct ARViewContainer: UIViewRepresentable {
    
    //callback function that sends it from view
    var onSessionCreated:(UncheckedSession) -> Void
    
    func makeUIView(context: Context) ->ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh // turns on lidar mesh
        }
        //start the camera and sensors
        arView.session.run(config)
        let wrappedSession = UncheckedSession(rawValue: arView.session)
        //dispatch session
        DispatchQueue.main.async {
            self.onSessionCreated(wrappedSession)
        }
        return arView
    }
    func updateUIView(_ uiView: ARView, context: Context) {}
}

//we do not mutate ARSession ever, so it is ok to send
struct UncheckedSession: @unchecked Sendable {
    let rawValue: ARSession
}
