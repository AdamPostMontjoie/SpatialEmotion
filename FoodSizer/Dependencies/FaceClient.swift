//
//  FaceClient.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 4/4/26.
//


import Foundation
import ARKit
import ComposableArchitecture
import simd

struct FaceClient: Sendable {
    var captureFace: @Sendable (_ session: UncheckedSession) async throws -> URL
}

extension FaceClient: DependencyKey {
    static let liveValue = Self(
        captureFace: {session in
            guard let frame = session.rawValue.currentFrame else { //ArFrame
                    struct FrameError: Error {}
                    throw FrameError()
            }
            let faceAnchors = frame.anchors.compactMap{$0 as? ARFaceAnchor}
            var objData = "# FoodSizer Face Scan\n"
            var globalVertexOffset = 1
            
            for fa in faceAnchors {
                let geometry = fa.geometry
                let vertices = geometry.vertices
                let indices = geometry.triangleIndices
                
                
                for vertex in vertices {
                    objData += "v \(vertex.x) \(vertex.y) \(vertex.z)\n"
                }
                
                for i in stride(from:0, to:indices.count, by:3){
                    // .obj files start counting at 1, so we add the globalVertexOffset
                    let v1 = Int(indices[i]) + globalVertexOffset
                    let v2 = Int(indices[i+1]) + globalVertexOffset
                    let v3 = Int(indices[i+2]) + globalVertexOffset
                    
                    objData += "f \(v1) \(v2) \(v3)\n"
                }
                globalVertexOffset += vertices.count
            }
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent("FaceScan-\(UUID().uuidString).obj")
            
            try objData.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        }
    )
}

extension DependencyValues {
    var faceClient: FaceClient {
        get { self[FaceClient.self] }
        set { self[FaceClient.self] = newValue }
    }
}
