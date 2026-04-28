//
//  SceneParsingClient.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 4/18/26.
//

import ComposableArchitecture
import SceneKit
import Foundation

struct SceneExtractionClient:Sendable {
    var parseNode: @Sendable (_ url: URL) async throws -> SCNNode
}

extension SceneExtractionClient:DependencyKey {
    static let liveValue = Self(
        //unpack scene node from scene file and returns
        parseNode: { fileUrl in
            //use url to extract file
            do {
                let scene = try SCNScene(url: fileUrl, options: nil)
                let node = scene.rootNode
                if node.childNodes.isEmpty {
                    throw SceneExtractionError.emptyOrCorruptedScene
                }
                return node.clone()
            } catch{
                print("failed to extract node from storage")
                throw error
            }
        }
    )
}

enum SceneExtractionError: Error, LocalizedError {
    case emptyOrCorruptedScene
    
    var errorDescription: String? {
        switch self {
        case .emptyOrCorruptedScene:
            return "The file was found, but it contained no 3D geometry."
        }
    }
}

extension DependencyValues {
    var sceneExtractionClient: SceneExtractionClient {
        get { self[SceneExtractionClient.self] }
        set { self[SceneExtractionClient.self] = newValue }
    }
}
