import ComposableArchitecture

@Reducer
struct ScannerPageFeature {
    @ObservableState
    struct State: Equatable {
        // 1. The Root (Always visible at the bottom of the stack)
        var camera = CameraFeature.State()
        // 2. The Hallway (For pushing the review screen)
        var path = StackState<Path.State>()
    }
    
    enum Action {
        case camera(CameraFeature.Action)
        case path(StackAction<Path.State, Path.Action>)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.camera, action: \.camera) {
            CameraFeature()
        }
        
        Reduce { state, action in
            switch action {
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
            }
        }
        .forEach(\.path, action: \.path)
    }
    
    @Reducer(state: .equatable)
    enum Path {
        case scanReview(ScanReviewFeature)
    }
}

