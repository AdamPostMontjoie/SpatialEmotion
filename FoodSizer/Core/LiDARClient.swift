//
//  LiDARClient.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/22/26.
//

import Foundation
import ARKit
import ComposableArchitecture
import simd

struct LiDARClient: Sendable {
    var captureMesh: @Sendable (_ session: UncheckedSession) async throws -> URL
}

extension LiDARClient: DependencyKey {
    static let liveValue = Self(
        captureMesh: {session in
            guard let frame = session.rawValue.currentFrame else {
                    struct FrameError: Error {}
                    throw FrameError()
            }
            let meshAnchors = frame.anchors.compactMap { $0 as? ARMeshAnchor }
        
            var objData = "# FoodSizer LiDAR Scan\n"
                        var globalVertexOffset = 1
            for ma in meshAnchors {
                    let geometry = ma.geometry
                    let transform = ma.transform
                    let vertices = geometry.vertices
                    let vertexPointer = vertices.buffer.contents()
                    
                // --- STEP A: EXTRACT VERTICES ---
                    for vIndex in 0..<vertices.count {
                        // Find exactly where this vertex lives in RAM
                        let byteOffset = vertices.offset + (vIndex * vertices.stride)
                        
                        // Read the X, Y, Z coordinates securely
                        let localVertex = vertexPointer.advanced(by: byteOffset).assumingMemoryBound(to: SIMD3<Float>.self).pointee
                        
                        // Convert the local point to a global point in the real room
                        let worldVertex4 = transform * SIMD4<Float>(localVertex.x, localVertex.y, localVertex.z, 1.0)
                        
                        // Append it to our text file format
                        objData.append("v \(worldVertex4.x) \(worldVertex4.y) \(worldVertex4.z)\n")
                    }
                let faces = geometry.faces
                let facePointer = faces.buffer.contents()
                let bytesPerFace = faces.bytesPerIndex * faces.indexCountPerPrimitive
                
                for fIndex in 0..<faces.count {
                    // Find the triangle in RAM
                    let byteOffset = fIndex * bytesPerFace
                    
                    // ARKit stores triangles as 3 4 byte integers
                    let indices = facePointer.advanced(by: byteOffset).bindMemory(to: UInt32.self, capacity: faces.indexCountPerPrimitive)
                    
                    // Add our global offset so the triangles connect to the correct vertices
                    let v1 = Int(indices[0]) + globalVertexOffset
                    let v2 = Int(indices[1]) + globalVertexOffset
                    let v3 = Int(indices[2]) + globalVertexOffset
                    
                    // Append the triangle face to the text file
                    objData.append("f \(v1) \(v2) \(v3)\n")
                }
                globalVertexOffset += vertices.count
            }
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent("Scan-\(UUID().uuidString).obj")
            
            try objData.write(to: fileURL, atomically: true, encoding: .utf8)
            
            return fileURL
        }
    )
}

extension DependencyValues {
    var lidarClient: LiDARClient {
        get { self[LiDARClient.self] }
        set { self[LiDARClient.self] = newValue }
    }
}
