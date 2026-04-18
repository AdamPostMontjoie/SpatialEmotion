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
    
    var onSessionCreated:(UncheckedSession) -> Void
    var currentMode:CameraMode
    var onReadyStateChanged: (Bool) -> Void
    
    @MainActor
        class Coordinator: NSObject, ARSessionDelegate {
            var parent: ARViewContainer
            var lastMode: CameraMode? = nil
            var lastReportedReadyState: Bool = false
            
            init(parent: ARViewContainer) {
                self.parent = parent
            }
            
            // nonisolated so it can run on the background hardware thread safely
            nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
                
                // non-sendable hardware data evaluated immediately on the background thread
                let hasFace = anchors.contains(where: { $0 is ARFaceAnchor })
                let hasMesh = anchors.contains(where: { $0 is ARMeshAnchor })
                
                // task run on main actor when
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    
                    let isReady: Bool
                    if self.parent.currentMode == .face {
                        isReady = hasFace
                    } else if self.parent.currentMode == .lidar {
                        isReady = hasMesh
                    } else {
                        isReady = false
                    }
                    // calls on ready state changed only if state has changed
                    if isReady != self.lastReportedReadyState {
                        self.lastReportedReadyState = isReady
                        self.parent.onReadyStateChanged(isReady)
                    }
                }
            }
        }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        arView.session.delegate = context.coordinator
        
        let wrappedSession = UncheckedSession(rawValue: arView.session)
        //dispatch session
        DispatchQueue.main.async {
            self.onSessionCreated(wrappedSession)
        }
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.parent = self
        
        guard self.currentMode != context.coordinator.lastMode else { return }
        context.coordinator.lastMode = self.currentMode
        switch self.currentMode{
            case .lidar:
            let config = ARWorldTrackingConfiguration()
                        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
                            config.sceneReconstruction = .meshWithClassification
                            uiView.debugOptions = [.showSceneUnderstanding]
                        }
                        uiView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        case .face:
            let config = ARFaceTrackingConfiguration()
            uiView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        case .off:
            uiView.session.pause()
        }
    }
}

//we do not mutate ARSession ever, so it is ok to send
struct UncheckedSession: @unchecked Sendable {
    let rawValue: ARSession
}
