//
//  ScanReviewFeature.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/22/26.
//

//
//  CameraFeature.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/22/26.
//
import ComposableArchitecture

@Reducer
struct ScanReviewFeature {
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
