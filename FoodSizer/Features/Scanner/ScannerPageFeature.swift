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
            case .camera(.delegate(.scanSavedToDb)):
                state.path.append(.scanReview(ScanReviewFeature.State()))
                return .none
            case .path(.popFrom(id: _)):
                state.camera.currentMode = .lidar //CameraMode.lidar
                state.camera.savedMeshUrl = nil //clear old urls
                state.camera.savedFaceUrl = nil
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

