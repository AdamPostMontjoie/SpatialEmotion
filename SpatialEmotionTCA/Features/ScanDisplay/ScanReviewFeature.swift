//
//  ScanReviewFeature.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/22/26.
//

//
//  CameraFeature.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/22/26.
//
import ComposableArchitecture
import Foundation
import SceneKit


@Reducer
struct ScanReviewFeature {
  @ObservableState
 struct State: Equatable {
        var scanId: UUID
        var objUrl: URL
        var faceUrl: URL
        var emotion:String
        var faceNode:SCNNode?
        var objNode:SCNNode?
        
      }
    enum Action {
        case deleteButtonTapped
        case onAppear
        case assembleFaceScene(SCNNode)
        case assembleObjectScene(SCNNode)
        case delegate(Delegate)
        enum Delegate{
            case scanRemoved(UUID)
            case scanFailedToLoad(UUID)
        }
      }
    @Dependency(\.databaseClient) var databaseClient
    @Dependency(\.sceneExtractionClient) var sceneExtractionClient
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
          case .onAppear:
              return .merge(
                .run { [url = state.faceUrl, id = state.scanId] send in
                        do {
                            let faceNode = try await sceneExtractionClient.parseNode(url)
                            //we have to send this back to the main thread
                            await send(.assembleFaceScene(faceNode))
                        }
                        catch {
                            await send(.delegate(.scanFailedToLoad(id)))
                        }
                    },
                .run { [url = state.objUrl, id = state.scanId] send in
                        do {
                            let objectNode = try await sceneExtractionClient.parseNode(url)
                            await send(.assembleObjectScene(objectNode))
                        }
                        catch {
                            await send(.delegate(.scanFailedToLoad(id)))
                        }
                    }
              )
      case let .assembleFaceScene(faceNode):
          state.faceNode = faceNode //saving the node allows it to be taken and used in sceneview
          return .none
      case let .assembleObjectScene(objectNode):
          state.objNode = objectNode
          return .none
          case .deleteButtonTapped:
            return .run {[id = state.scanId, obj = state.objUrl, face = state.faceUrl] send in
                do {
                try await databaseClient.deleteSession(id,obj,face)
                print("SUCCESS: Deleted from SSD and SwiftData")
                    await send(.delegate(.scanRemoved(id)))
                 } catch {
                   print("ERROR: Failed to delete - \(error)")
                   }
              }
          case .delegate:
              return .none
          }
    }
  }
}
