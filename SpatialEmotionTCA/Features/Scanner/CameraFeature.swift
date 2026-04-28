//
//  CameraFeature.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/22/26.
//
import ComposableArchitecture
import Foundation

@Reducer
struct CameraFeature {
  @ObservableState
    struct State:Equatable {
     var currentMode:CameraMode = .lidar
     var savedMeshUrl:URL?
     var savedFaceUrl:URL?
     var detectedEmotion:String?
     var isReadyToScan: Bool = false
     var isSaving:Bool = false
    }
    
    enum Action {
        case scanButtonTapped
        case scanCompleted(URL, String?)
        case saveToDataBase
        case onDisappear
        case onAppear
        case delegate(Delegate)
        case readyStateChanged(isReady:Bool)
        case setMode(CameraMode)
        enum Delegate {
            case scanSavedToDb(scanId:UUID,objUrl:URL,faceUrl:URL, emotion:String)
        }
      }
    @Dependency(\.uuid) var uuid
    @Dependency(\.lidarClient) var lidarClient
    @Dependency(\.faceClient) var faceClient
    @Dependency(\.databaseClient) var databaseClient
var body: some Reducer<State, Action> {
    Reduce { state, action in
        switch action {
        case let .readyStateChanged(isReady):
            state.isReadyToScan = isReady
            return .none
        case .onAppear:
            // Only turn it back on if we aren't in the middle of a scan
            if state.savedMeshUrl == nil {
                state.currentMode = .lidar
            } else if state.savedFaceUrl == nil {
                state.currentMode = .face
            }
            return .none
        case .onDisappear:
            state.currentMode = .off
            state.isReadyToScan = false
            return .none
        case let .setMode(mode):
            state.currentMode = mode
            return .none
        case .scanButtonTapped:
            print("button tapped")
            state.isSaving = true
            return .none
            
        case let .scanCompleted(url,emotion):
            state.isSaving = false
            if state.savedMeshUrl == nil {
                state.savedMeshUrl = url
                state.isReadyToScan = false
                print("SUCCESS: Face Mesh saved to \(url)")
                return .run { send in
                    //state is mutated asynchronously to give the arview time to turn everything off
                    //before turning it back on again
                    await send(.setMode(.off))
                    try await Task.sleep(for: .milliseconds(30))
                    await send(.setMode(.face))
                }
            }
            else {
                state.savedFaceUrl = url
                state.detectedEmotion = emotion
                state.currentMode = .off
                print("SUCCESS: Face Mesh saved to \(url)")
                return .send(.saveToDataBase)
            }
        case .saveToDataBase:
            guard let objUrl = state.savedMeshUrl,
                let faceUrl = state.savedFaceUrl,
                let emotion = state.detectedEmotion
            else{
                return .none
            }
            let newScanId = self.uuid()
            return .run { send in
                    do {
                        try await databaseClient.saveSession(newScanId,objUrl,faceUrl,emotion)
                        print("SUCCESS: Database saved.")
                        await send(.delegate(.scanSavedToDb(scanId: newScanId, objUrl: objUrl, faceUrl: faceUrl, emotion:emotion)))
                        
                    } catch {
                        print("ERROR: Failed to save to DB - \(error)")
                    }
                }
        case .delegate:
            return .none
      }
    }
  }
}

enum CameraMode:Equatable {
    case lidar //trigger this case from outside. 
    case face
    case off
}
