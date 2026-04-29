//
//  ArViewContainer.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/22/26.
//

import SwiftUI
import ARKit
import RealityKit
import Dependencies


@MainActor
struct ARViewContainer: UIViewRepresentable {
    var saveSessionNow:Bool
    var currentMode:CameraMode
    var onSessionSaved: (URL, String?) -> Void
    var onReadyStateChanged: (Bool) -> Void

    @Dependency(\.lidarClient) var lidarClient
    @Dependency(\.faceClient) var faceClient
    @Binding var liveEmotion:String?
    
    @MainActor
        class Coordinator: NSObject, ARSessionDelegate {
            var parent: ARViewContainer
            var lastMode: CameraMode? = nil
            var lastReportedReadyState: Bool = false
            var isExtracting: Bool = false
            var lastDetectedEmotion:String?
            
            init(parent: ARViewContainer) {
                self.parent = parent
            }
            
            // nonisolated so it can run on the background hardware thread safely
            nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
                
                // non-sendable hardware data evaluated immediately on the background thread
                let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first
                let hasFace = (faceAnchor != nil)
                let hasMesh = anchors.contains(where: { $0 is ARMeshAnchor })
                var detectedEmotionString:String?
                
                //check emotion
                let emote = EmotionClassification()
                
                if let anchor = faceAnchor{
                  detectedEmotionString = emote.detectEmotion(face: anchor)
                    
                }
                
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
                    if self.parent.currentMode == .face {
                        if detectedEmotionString != self.lastDetectedEmotion {
                            self.lastDetectedEmotion = detectedEmotionString
                            self.parent.liveEmotion = detectedEmotionString
                        }
                    } else if self.lastDetectedEmotion != nil {
                        // Clear it out if we switch to LiDAR or Off
                        self.lastDetectedEmotion = nil
                        self.parent.liveEmotion = nil
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
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.parent = self
        if self.saveSessionNow && !context.coordinator.isExtracting {
            context.coordinator.isExtracting = true
            if let frame = uiView.session.currentFrame {
                let payload = frame.anchors
                let mode = self.currentMode
                    Task {
                        do {
                            if mode == .lidar {
                                let url = try await self.lidarClient.captureMesh(payload)
                                    await MainActor.run {
                                        self.onSessionSaved(url, nil)
                                        //we wait until the next updateuiview to set the isExtracting lock to false
                                        //when we set it immediately after, it was running updateuiview before tca reducer could set is saving to false
                                        //so savesessionnow listener was still true and it saved twice as isExtracting was now false
                                    }
                            } else if mode == .face {
                                let (url,emotion) = try await self.faceClient.captureFace(payload)
                                await MainActor.run {
                                    self.onSessionSaved(url, emotion)
                                }
                            }
                        } catch {
                            await MainActor.run {
                                context.coordinator.isExtracting = false
                            }
                        }
                    }
            } else {
                context.coordinator.isExtracting = false
            }
        } else if !self.saveSessionNow {
            context.coordinator.isExtracting = false
        }
        
        
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
    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
        uiView.session.delegate = nil
        uiView.scene.anchors.removeAll()
        uiView.removeFromSuperview()
    }
}

//we do not mutate ARSession ever, so it is ok to send
struct UncheckedSession: @unchecked Sendable {
    let rawValue: ARSession
}
