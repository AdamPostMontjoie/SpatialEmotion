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
    var captureMesh: @Sendable (_ payload: [ARAnchor]) async throws -> URL
}
//this may not be properly saving meshes
extension LiDARClient: DependencyKey {
    static let liveValue = Self(
        captureMesh: {payload in
  
            let meshAnchors = payload.compactMap { $0 as? ARMeshAnchor }
           
            let scene = SCNScene()
            
            for ma in meshAnchors {
                    let geometry = ma.geometry
                   
                    let transform = ma.transform
                    let vertices = geometry.vertices
                    let vertexPointer = vertices.buffer.contents()
                    
                var scnVertices: [SCNVector3] = []
                scnVertices.reserveCapacity(vertices.count) //reserves enough memory for count * Scnvector3
                    
                for vIndex in 0..<vertices.count {
                    let byteOffset = vertices.offset + (vIndex * vertices.stride)
                    // Read the local X, Y, Z
                    let localVertex = vertexPointer.advanced(by: byteOffset).assumingMemoryBound(to: SIMD3<Float>.self).pointee
                    // Convert to SceneKit's vector format
                    scnVertices.append(SCNVector3(localVertex.x, localVertex.y, localVertex.z))
                }
                    
                let faces = geometry.faces
                let facePointer = faces.buffer.contents()
                let bytesPerFace = faces.bytesPerIndex * faces.indexCountPerPrimitive
                let classificationBuffer = geometry.classification
                var scnIndices: [Int32] = []
                scnIndices.reserveCapacity(faces.count * 3) // 3 points per triangle
                
                for fIndex in 0..<faces.count {
                    let byteOffset = fIndex * bytesPerFace
                    let indices = facePointer.advanced(by: byteOffset).bindMemory(to: UInt32.self, capacity: 3)
                    

                    scnIndices.append(Int32(indices[0]))
                    scnIndices.append(Int32(indices[1]))
                    scnIndices.append(Int32(indices[2]))
                }
                let source = SCNGeometrySource(vertices: scnVertices)
                let element = SCNGeometryElement(indices: scnIndices, primitiveType: .triangles)
                let scnGeometry = SCNGeometry(sources: [source], elements: [element])
                
                let node = SCNNode(geometry: scnGeometry)
                node.simdTransform = ma.transform
                
                scene.rootNode.addChildNode(node)
            }
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent("ObjectScan-\(UUID().uuidString).usdz")
            
            let success = scene.write(to: fileURL, options: nil, delegate: nil, progressHandler: nil)
            
            if success {
                return fileURL
            } else {
                struct WriteError: Error {}
                throw WriteError()
            }
        }
    )
}

extension DependencyValues {
    var lidarClient: LiDARClient {
        get { self[LiDARClient.self] }
        set { self[LiDARClient.self] = newValue }
    }
}
