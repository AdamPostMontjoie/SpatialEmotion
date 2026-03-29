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
     var savedMeshUrl:URL?
    }
    enum Action {
        case scanButtonTapped
        case sessionCreated(UncheckedSession)
        case scanCompleted(URL)
      }
    @Dependency(\.lidarClient) var lidarClient
var body: some Reducer<State, Action> {
    Reduce { state, action in
        switch action {
        case let .sessionCreated(sesh):
            state.session = sesh
            return .none
        case .scanButtonTapped:
            guard let session = state.session else { return .none }
            
            return .run{ send in
                let fileUrl = try await lidarClient.captureMesh(session)
                await send(.scanCompleted(fileUrl))
            }
        case let .scanCompleted(url):
            state.savedMeshUrl = url
            return .none
          
      }
    }
  }
}
