//
//  PastScanDetail.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/21/26.
//

import ComposableArchitecture

@Reducer
struct PastScanDetailFeature {
    @ObservableState
    struct State: Equatable {
        var name:String?
    }
    enum Action {
        case nameTapped
    }
    var body: some ReducerOf<Self> {
        Reduce {state, action in
            switch action {
            case .nameTapped:
                if let unwrappedName = state.name {
                    state.name = "I wasn't null but before " + unwrappedName
                } else{
                    state.name = "I was null"
                }
                return .none
            }
        }
    }
}
