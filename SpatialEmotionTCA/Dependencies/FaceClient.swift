//
//  FaceClient.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 4/4/26.
//


import Foundation
import ARKit
import ComposableArchitecture
import SceneKit

struct FaceClient: Sendable {
    var captureFace: @Sendable (_ session: UncheckedSession) async throws -> URL
}

extension FaceClient: DependencyKey {
    static let liveValue = Self(
        captureFace: {session in
            guard let frame = session.rawValue.currentFrame,
                  let fa = frame.anchors.compactMap({ $0 as? ARFaceAnchor }).first,
                let device = MTLCreateSystemDefaultDevice(),
                let faceGeometry = ARSCNFaceGeometry(device: device)
            else { //ArFrame
                    struct FrameError: Error {}
                    throw FrameError()
            }
            faceGeometry.update(from: fa.geometry)
            let node = SCNNode(geometry: faceGeometry)
            let scene = SCNScene()
            scene.rootNode.addChildNode(node)
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent("FaceScan-\(UUID().uuidString).usdz")
            
            
            let success = scene.write(to: fileURL, options: nil, delegate: nil, progressHandler: nil)
    
            if success{
                return fileURL
            } else {
                struct WriteError: Error {}
                throw WriteError()
            }
            
        }
    )
}

extension DependencyValues {
    var faceClient: FaceClient {
        get { self[FaceClient.self] }
        set { self[FaceClient.self] = newValue }
    }
}
