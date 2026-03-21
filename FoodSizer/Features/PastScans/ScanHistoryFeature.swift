//
//  HistoryFeature.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/21/26.
//

import ComposableArchitecture

@Reducer
struct HistoryFeature {
    @ObservableState
    struct State:Equatable {
        @Presents var destination:Destination.State?
        var scans: IdentifiedArrayOf<PastScan> = []
        var path = StackState<PastScanDetailFeature.State>()
    }
}

struct PastScan: Equatable, Identifiable {
    let id: UUID
    var name: String
    var info: Int
}

extension HistoryFeature {
    @Reducer(state: .equatable)
    enum Destination {
        case addContact(AddContactFeature)
        case alert(AlertState<ContactsFeature.Action.Alert>)
    }
}
