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
            print("session created")
            return .none
        case .scanButtonTapped:
            print("button tapped")
            guard let session = state.session else { return .none }
            print("creating mesh")
            return .run{ send in
                let fileUrl = try await lidarClient.captureMesh(session)
                await send(.scanCompleted(fileUrl))
            }
        case let .scanCompleted(url):
            state.savedMeshUrl = url
            print("SUCCESS: Mesh saved to \(url)")
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
        lhs.savedMeshUrl == rhs.savedMeshUrl
    }
}
