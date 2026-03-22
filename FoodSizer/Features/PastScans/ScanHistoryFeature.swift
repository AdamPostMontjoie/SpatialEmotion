//
//  HistoryFeature.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/21/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ScanHistoryFeature {
    @ObservableState
    struct State:Equatable {
        @Presents var destination:Destination.State?
        var scans: IdentifiedArrayOf<PastScan> = [
            PastScan(id: UUID(), name: "Apple", info: 150),
            PastScan(id: UUID(), name: "Bowl of Rice", info: 350)
        ]
        var path = StackState<PastScanDetailFeature.State>()
    }
    enum Action {
        case destination(PresentationAction<Destination.Action>)
        case path(StackAction<PastScanDetailFeature.State,PastScanDetailFeature.Action>)
        case deleteButtonTapped(id: PastScan.ID)
        enum Alert:Equatable {
            case confirmDeletion(id:PastScan.ID)
        }
        
    }
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            
            case .path:
                return .none
            case let .deleteButtonTapped(id):
                state.destination = .alert(.deleteConfirmation(id: id))
                return .none
            case let .destination(.presented(.alert(.confirmDeletion(id: id)))):
                state.scans.remove(id: id)
                return .none
            case .destination:
                return .none
            }
            
        }
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.path, action: \.path) {
                PastScanDetailFeature()
            }
    }
}

struct PastScan: Equatable, Identifiable {
    let id: UUID
    var name: String
    var info: Int
}

extension ScanHistoryFeature {
    @Reducer(state: .equatable)
    enum Destination {
        case alert(AlertState<ScanHistoryFeature.Action.Alert>)
    }
}
extension AlertState where Action == ScanHistoryFeature.Action.Alert {
  static func deleteConfirmation(id: UUID) -> Self {
    Self {
      TextState("Are you sure?")
    } actions: {
      ButtonState(role: .destructive, action: .confirmDeletion(id: id)) {
        TextState("Delete")
      }
    }
  }
}
