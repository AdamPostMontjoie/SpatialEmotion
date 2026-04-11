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
    }
    
    enum Action {
        case scanButtonTapped
        case sessionCreated(UncheckedSession)
        case scanCompleted(URL)
        case saveToDataBase
        case delegate(Delegate)
        enum Delegate {
           case scanSavedToDb
        }
      }
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
        case .scanButtonTapped:
            print("button tapped")
            guard let session = state.session else { return .none }
            print("creating mesh")
            if state.savedMeshUrl == nil{ //lidar scan
                return .run { send in
                    let fileUrl = try await lidarClient.captureMesh(session)
                    await send(.scanCompleted(fileUrl))
                }
            }
            else { //face scan
                return .run { send in
                    let fileUrl = try await faceClient.captureFace(session)
                    await send(.scanCompleted(fileUrl))
                }
            }
            
        case let .scanCompleted(url):
            if state.savedMeshUrl == nil {
                state.savedMeshUrl = url
                print("SUCCESS: Object Mesh saved to \(url)")
                state.currentMode = .face
                return .none
            }
            else {
                state.savedFaceUrl = url
                state.currentMode = .off
                print("SUCCESS: Face Mesh saved to \(url)")
                return .send(.saveToDataBase)
            }
        case .saveToDataBase:
            guard let objUrl = state.savedMeshUrl, let faceUrl = state.savedFaceUrl
            else{
                return .none
            }
            return .run { send in
                    do {
                        try databaseClient.saveSession(objUrl, faceUrl)
                        print("SUCCESS: Database saved.")
                        
                        //trigger navigation to review screen
                       // await send(.delegate(.scanSuccessfullySaved))
                        await send(.delegate(.scanSavedToDb))
                        
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
