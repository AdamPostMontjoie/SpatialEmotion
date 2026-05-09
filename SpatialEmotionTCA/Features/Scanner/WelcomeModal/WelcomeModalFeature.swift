//
//  WelcomeModal.swift
//  SpatialEmotion
//
//  Created by Adam Post-Montjoie on 5/9/26.
//

import ComposableArchitecture

@Reducer
struct WelcomeModalFeature {
  @ObservableState
 struct State: Equatable {
        var count = 0
        var numberFact: String?
      }
    enum Action {
        case decrementButtonTapped
        case incrementButtonTapped
        case numberFactButtonTapped
        case numberFactResponse(String)
      }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .decrementButtonTapped:
        state.count -= 1
        return .none

      case .incrementButtonTapped:
        state.count += 1
        return .none

      case .numberFactButtonTapped:
          return .none
        

      case let .numberFactResponse(fact):
        state.numberFact = fact
        return .none
      }
    }
  }
}
