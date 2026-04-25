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
 struct State {
     var session:UncheckedSession?
     var currentMode:CameraMode = .lidar
     var savedMeshUrl:URL?
     var savedFaceUrl:URL?
     var detectedEmotion:String?
     var isReadyToScan: Bool = false
    }
    
    enum Action {
        case scanButtonTapped
        case sessionCreated(UncheckedSession)
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
        case let .sessionCreated(sesh):
            state.session = sesh
            print("session created")
            return .none
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
            return .none
        case let .setMode(mode):
            state.currentMode = mode
            return .none
        case .scanButtonTapped:
            print("button tapped")
            guard let session = state.session else { return .none }
            print("creating mesh")
            if state.savedMeshUrl == nil{ //lidar scan
                return .run { send in
                    let fileUrl = try await lidarClient.captureMesh(session)
                    await send(.scanCompleted(fileUrl, nil))
                }
            }
            else { //face scan
                return .run { send in
                    let (fileUrl, emotion)  = try await faceClient.captureFace(session)
                    await send(.scanCompleted(fileUrl, emotion))
                }
            }
            
        case let .scanCompleted(url,emotion ):
            if state.savedMeshUrl == nil {
                state.savedMeshUrl = url
                state.isReadyToScan = false
                return .run { send in
                    //state is mutated asynchronously to give the arview time to turn everything off
                    //before turning it back on again
                    await send(.setMode(.off))
                    try await Task.sleep(for: .milliseconds(300))
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
                        //trigger navigation to review screen
                       // await send(.delegate(.scanSuccessfullySaved))
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
//this is operator overloading, in Swift == is just a func
//cannot compare Arsession as it is a reference type and doesn't support it
//so overwriting == to make it equatable for tca
extension CameraFeature.State: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.savedMeshUrl == rhs.savedMeshUrl &&
        lhs.savedFaceUrl == rhs.savedFaceUrl &&
        lhs.currentMode == rhs.currentMode
        
    }
}

enum CameraMode:Equatable {
    case lidar //trigger this case from outside. 
    case face
    case off
}
