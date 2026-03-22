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
        // Connect the Camera child to this parent
        Scope(state: \.camera, action: \.camera) {
            CameraFeature()
        }
        
        Reduce { state, action in
            switch action {
            // Intercept the camera button tap and trigger the navigation     
            case .camera:
                return .none
                
            case .path:
                return .none
            }
        }
        // Connect the Path enum
        .forEach(\.path, action: \.path)
    }
    
    // Notice Camera is removed from here. Only pushed screens go in the Path.
    @Reducer(state: .equatable)
    enum Path {
        case scanReview(ScanReviewFeature)
    }
}
