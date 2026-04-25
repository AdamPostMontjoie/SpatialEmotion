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
        var scans: IdentifiedArrayOf<PairedScan> = []
        var path = StackState<ScanReviewFeature.State>()
    }
    enum Action {
        case onAppear
        case scansLoaded([PairedScan])
        case destination(PresentationAction<Destination.Action>)
        case path(StackAction<ScanReviewFeature.State,ScanReviewFeature.Action>)
        case deleteButtonTapped(id:PairedScan.ID)
        enum Alert:Equatable {
            case scanUnavailable(id:PairedScan.ID)
            case confirmDeletion(id:PairedScan.ID)
        }
        
    }
    @Dependency(\.databaseClient) var databaseClient
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    do {
                        let sessions = try databaseClient.fetchAllSessions()
                        let pastScans = sessions.map {
                            PairedScan(id: $0.id, name: $0.name, timestamp: $0.timestamp, objUrl: $0.scanOneURL, faceUrl: $0.scanTwoURL)
                        }
                        await send(.scansLoaded(pastScans))
                    } catch {
                        print("ERROR: Failed to fetch sessions - \(error)")
                    }
                }
                            
            case let .scansLoaded(scans):
                state.scans = IdentifiedArray(uniqueElements: scans)
                return .none
            case let .path(.element(id: _, action: .delegate(.scanFailedToLoad(scanId)))):
                            _ = state.path.popLast()
                            state.destination = .alert(.scanUnavailable(id: scanId))
                            return .none
            case let .path(.element(id: _, action: .delegate(.scanRemoved(scanId)))):
                state.scans.remove(id: scanId)
                return .none
            case let .deleteButtonTapped(id):
                state.destination = .alert(.deleteConfirmation(id: id))
                return .none
            case .path:
                return .none
            case let .destination(.presented(.alert(.confirmDeletion(id: id)))),
                let .destination(.presented(.alert(.scanUnavailable(id: id))))
                :
                guard let scanToDelete = state.scans[id:id] else {return .none}
                state.scans.remove(id: id)
                
                return .run { _ in
                    do {
                    try await databaseClient.deleteSession(scanToDelete.id,scanToDelete.objUrl,scanToDelete.faceUrl)
                    print("SUCCESS: Deleted from SSD and SwiftData")
                     } catch {
                       print("ERROR: Failed to delete - \(error)")
                       }
                  }

            case .destination:
                return .none
            }
            
        }
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.path, action: \.path) {
                ScanReviewFeature()
            }
        ._printChanges()
    }
}
struct PairedScan:Equatable, Identifiable {
    let id: UUID
    let name: String
    let timestamp: Date
    let objUrl:URL
    let faceUrl:URL
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
    static func scanUnavailable(id: UUID) -> Self {
      Self {
        TextState("Sorry, no file can be found")
      } actions: {
          ButtonState(role: .destructive, action: .scanUnavailable(id: id)) {
          TextState("Ok")
        }
      }
    }
}
