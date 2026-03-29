//
//  LiDARClient.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/22/26.
//

import Foundation
import ARKit
import ComposableArchitecture

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
            
            let mockObjData = "# OBJ File Placeholder\n# Found \(meshAnchors.count) meshes."
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent("Scan-\(UUID().uuidString).obj")
            
            try mockObjData.write(to: fileURL, atomically: true, encoding: .utf8)
            
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
