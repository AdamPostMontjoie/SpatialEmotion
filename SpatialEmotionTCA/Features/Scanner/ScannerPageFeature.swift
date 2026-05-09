import ComposableArchitecture
import Sharing
import Foundation

@Reducer
struct ScannerPageFeature {
    @ObservableState
    struct State: Equatable {
        // Always visible
        var camera = CameraFeature.State()
        // Path to slide on review screen
        var path = StackState<Path.State>()
        //determines if user has read welcome modal yet from userdefaults
        @Shared(.appStorage("completedWelcome")) var completedWelcome = false
        //popup
        @Presents var destination:Destination.State?
    }
    
    enum Action {
        case onAppear
        case camera(CameraFeature.Action)
        case path(StackAction<Path.State, Path.Action>)
        case destination(PresentationAction<Destination.Action>)
        enum Alert:Equatable {
            case finishedWelcome
        }
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.camera, action: \.camera) {
            CameraFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                if !state.completedWelcome {
                    state.camera.currentMode = .off
                    state.destination = .alert(.welcome())
                } else {
                    return .send(.camera(.onAppear))
                }
                return .none
            case .destination(.presented(.alert(.finishedWelcome))):
                    state.$completedWelcome.withLock {$0 = true}
                    return .send(.camera(.onAppear))
                    return .none
                
            case let .camera(.delegate(.scanSavedToDb(id,obj,face,emotion))):
                
                let reviewState = ScanReviewFeature.State(
                    scanId:id,
                    objURL:obj,
                    faceURL:face,
                    emotion:emotion
                )
                state.path.append(.scanReview(reviewState))
                return .none
            case .path(.popFrom(id: _)):
                state.camera.currentMode = .lidar //CameraMode.lidar
                state.camera.savedMeshUrl = nil //clear old urls
                state.camera.savedFaceUrl = nil
                //null nodes just in case lol
                if let lastId = state.path.ids.last,
                   case let .scanReview(reviewState) = state.path[id: lastId] {
                    
                    var modifiedState = reviewState
                    modifiedState.faceNode = nil
                    modifiedState.objNode = nil
                    
                    state.path[id: lastId] = .scanReview(modifiedState)
                }
                return .none
            case .path(.element(id:_, action: .scanReview(.delegate(.scanRemoved(_))))):
                state.path.removeLast()
                state.camera.currentMode = .lidar //CameraMode.lidar
                state.camera.savedMeshUrl = nil //clear old urls
                state.camera.savedFaceUrl = nil
                state.camera.detectedEmotion = nil
                return .none
            case .camera:
                return .none
            case .path:
                return .none
            case .destination:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$destination, action: \.destination)
    }
    
    @Reducer
    enum Path {
        case scanReview(ScanReviewFeature)
    }
}
extension ScannerPageFeature {
    @Reducer
    enum Destination {
        //configure alert
        case alert(AlertState<ScannerPageFeature.Action.Alert>)
    }
}
extension AlertState where Action == ScannerPageFeature.Action.Alert {
    static func welcome() -> Self {
        Self {
            TextState("Welcome to SpatialEmotion")
        } actions: {
            // 3. Map the button to your Action.Alert case
            ButtonState(action: .finishedWelcome) {
                TextState("OK")
            }
        } message: {
            TextState("This app uses your FaceID TrueDepth and LiDAR sensor to capture your emotion and the place where you felt it in 3D")
        }
    }
}
extension ScannerPageFeature.Path.State: Equatable {}
extension ScannerPageFeature.Destination.State: Equatable {}
