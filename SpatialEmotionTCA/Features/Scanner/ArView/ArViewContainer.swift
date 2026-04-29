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
    
    @MainActor
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        weak var arView: ARView? //this pointer is weak to avoid retain cycle with the coordinator, as arview already owns pointer to coordinator
        
        var lastMode: CameraMode? = nil
        var lastReportedReadyState: Bool = false
        var isExtracting: Bool = false
        var lastDetectedEmotion:String?
        
        // RealityKit Trackers
        var faceAnchorEntity: AnchorEntity?
        var emojiModelEntity: ModelEntity?
        
        init(parent: ARViewContainer) {
            self.parent = parent
        }
        
        // nonisolated so it can run on the background hardware thread safely
        nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            
            // non-sendable hardware data evaluated immediately on the background
            let allTrackedAnchors = session.currentFrame?.anchors ?? []
            
            let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first
            
            let hasFace = allTrackedAnchors.contains(where: { $0 is ARFaceAnchor })
            let hasMesh = allTrackedAnchors.contains(where: { $0 is ARMeshAnchor })
            var detectedEmotionString:String?
            
            //check emotion
            let emote = EmotionClassification()
            
            if let anchor = faceAnchor{
              detectedEmotionString = emote.detectEmotion(face: anchor)
            }
            
            // task run on main actor when
            Task { @MainActor [weak self] in
                guard let self = self, let arView = self.arView else { return }
                
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
                    // only update emoji if needed
                    if let newEmotion = detectedEmotionString, newEmotion != self.lastDetectedEmotion {
                        self.lastDetectedEmotion = newEmotion
                        let emojiString = EmotionClassification().emotionToEmoji(newEmotion)
                        self.updateLiveEmoji(emoji: emojiString, in: arView)
                    }
                } else if self.lastDetectedEmotion != nil {
                    // Clear it out if we switch to LiDAR or Off
                    self.lastDetectedEmotion = nil
                    
                    // Destroy the 3D objects when leaving Face Mode
                    self.faceAnchorEntity?.removeFromParent()
                    self.faceAnchorEntity = nil
                    self.emojiModelEntity = nil
                }
            }
        }
        
        func createEmojiTexture(emoji: String) -> TextureResource? {
                    let size = CGSize(width: 256, height: 256)
                    let renderer = UIGraphicsImageRenderer(size: size)
                    
                    let image = renderer.image { context in
                        UIColor.clear.set()
                        context.fill(CGRect(origin: .zero, size: size))
                        
                        let font = UIFont.systemFont(ofSize: 200)
                        let attributes: [NSAttributedString.Key: Any] = [.font: font]
                        let stringSize = emoji.size(withAttributes: attributes)
                        
                        // Center the emoji on the canvas
                        let rect = CGRect(x: (size.width - stringSize.width) / 2,
                                          y: (size.height - stringSize.height) / 2,
                                          width: stringSize.width,
                                          height: stringSize.height)
                        
                        emoji.draw(in: rect, withAttributes: attributes)
                    }
                    
                    guard let cgImage = image.cgImage else { return nil }
                    let options = TextureResource.CreateOptions(semantic: .color)
                    return try? TextureResource(image: cgImage, options: options)
                }
        func updateLiveEmoji(emoji: String, in arView: ARView) {
                    guard let texture = createEmojiTexture(emoji: emoji) else { return }
    
                    var material = UnlitMaterial()
                    material.color = .init(texture: .init(texture))
                    material.blending = .transparent(opacity: 1.0)
                    
                    if let existingEntity = self.emojiModelEntity {
                        existingEntity.model?.materials = [material]
                    } else {
                        // Generate a flat 15cm x 15cm 2D plane
                        let mesh = MeshResource.generatePlane(width: 0.15, height: 0.15)
                        let newEntity = ModelEntity(mesh: mesh, materials: [material])
                        
                        // up .1 so user sees face, out .1 for clipping
                        newEntity.position = [0.0, 0.1, 0.1]
                        
                        let anchor = AnchorEntity(.face)
                        anchor.addChild(newEntity)
                        self.emojiModelEntity = newEntity
                        self.faceAnchorEntity = anchor
                        arView.scene.addAnchor(anchor)
                    }
                }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        arView.session.delegate = context.coordinator
        context.coordinator.arView = arView // Save the pointer to the Coordinator
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.parent = self
        
        //the session saving that triggers based on tca state
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
        
        //the mode and session switching based on tca state
        guard self.currentMode != context.coordinator.lastMode else { return }
        context.coordinator.lastMode = self.currentMode
        context.coordinator.lastReportedReadyState = false
        
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
