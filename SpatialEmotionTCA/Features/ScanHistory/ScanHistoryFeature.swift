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
        case unavailableAlert
        case successAlert
        case failureAlert
        enum Alert:Equatable {
            case scanUnavailable
            case confirmDeletion(id:PairedScan.ID)
            case deletionSuccess
            case deletionFailure
        }
        
    }
    @Dependency(\.databaseClient) var databaseClient
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                // Lifecycle
                case .onAppear:
                    return .run { send in
                        do {
                            let sessions = try databaseClient.fetchAllSessions()
                            let pastScans = sessions.map {
                                PairedScan(id: $0.id, name: $0.name, timestamp: $0.timestamp, objURL: $0.objURL, faceURL: $0.faceURL, emotion: $0.emotion)
                            }
                            await send(.scansLoaded(pastScans))
                        } catch {
                            print("ERROR: Failed to fetch sessions - \(error)")
                        }
                    }
                                
                // View Actions
                case let .deleteButtonTapped(id): //display the delete confirmation alert
                    state.destination = .alert(.deleteConfirmation(id: id))
                    return .none

                //  Internal actions
                case let .scansLoaded(scans):
                    state.scans = IdentifiedArray(uniqueElements: scans)
                    return .none

                case  .unavailableAlert:
                    // Display the alert
                    state.destination = .alert(.scanUnavailable())
                    return .none

                case .successAlert
                    :
                    state.destination = .alert(.deletionSuccess())
                    return .none

                case .failureAlert,
                        .path(.element(id: _, action: .delegate(.scanFailedToRemove)))
                    :
                    state.destination = .alert(.deletionFailure())
                    return .none

                //  Destination
                case let .destination(.presented(.alert(.confirmDeletion(id: id))))
                    :
                    guard let scanToDelete = state.scans[id:id] else {return .none}
                    state.scans.remove(id: id)
                    
                    return .run { send in
                        do {
                        try await databaseClient.deleteSession(scanToDelete.id,scanToDelete.objURL,scanToDelete.faceURL)
                            await send(.successAlert)
                        print("SUCCESS: Deleted from SSD and SwiftData")
                            
                     } catch {
                           print("ERROR: Failed to delete - \(error)")
                             await send(.failureAlert)
                           }
                      }

                case .destination(.presented(.alert(.scanUnavailable))):
                    return .none

                case .destination:
                    return .none

                // path
                case let .path(.element(id: _, action: .delegate(.scanFailedToLoad(scanId)))):
                    guard let corruptedScan = state.scans[id: scanId] else { return .none }
                   state.scans.remove(id: scanId)
                    return .run { send in
                        //destroy corrupted urls
                        try? await databaseClient.deleteSession(corruptedScan.id, corruptedScan.objURL, corruptedScan.faceURL)
                        try await Task.sleep(for: .milliseconds(450))
                        await send(.unavailableAlert)
                    }

                case let .path(.element(id: _, action: .delegate(.scanRemoved(scanId)))):
                    state.scans.remove(id: scanId)
                    return .run { send in
                        //sleep
                            try await Task.sleep(for: .milliseconds(450))
                            await send(.successAlert)
                        }

                case .path:
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
    let objURL:URL
    let faceURL:URL
    let emotion:String
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
    static func scanUnavailable() -> Self {
      Self {
        TextState("Sorry, no file can be found")
      } actions: {
          ButtonState( action: .scanUnavailable) {
          TextState("Ok")
        }
      }
    }
    static func deletionSuccess() -> Self {
        Self {
            TextState("Scan Deleted")
        }
    }
    static func deletionFailure() -> Self {
        Self {
            TextState("Sorry, failed to delete for some reason")
        }
    }
}
