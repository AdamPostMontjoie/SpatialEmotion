//
//  RootFeature.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/21/26.
//

import ComposableArchitecture

@Reducer
struct RootFeature {
    @ObservableState
    struct State: Equatable {
        // This path manages the transition from Home -> History
        var historyTab = ScanHistoryFeature.State()
        var selectedTab:Tab = .camera
        
    }
    
    enum Tab { case camera, history }
    enum Action {
        case historyTab(ScanHistoryFeature.Action)
        case selectedTab(Tab)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.historyTab, action: \.historyTab) {
                ScanHistoryFeature()
           }
        Reduce { state, action in
            switch action {
            case let .selectedTab(tab):
                state.selectedTab = tab
                return .none
            case .historyTab:
                return .none
                
            }
        }
    }
}

