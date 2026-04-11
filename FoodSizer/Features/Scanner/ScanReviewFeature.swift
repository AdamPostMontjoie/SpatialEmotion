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
           var scanId: UUID
           var objUrl: URL
           var faceUrl: URL
      }
    enum Action {
        case deleteButtonTapped
        case delegate(Delegate)
        enum Delegate{
            case scanRemoved
        }
      }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .deleteButtonTapped:
        return .run {[id = state.scanId, obj = state.objUrl, face = state.faceUrl] send in
           //   await try deleteScanClient //implement to delete urls from swiftdata and phone
            do {
            // try await deleteScanClient.delete(id: id, objUrl: obj, faceUrl: face)
            print("SUCCESS: Deleted from SSD and SwiftData")
                              
                              // 3. Fire the delegate directly from the background thread!
                await send(.delegate(.scanRemoved))
             } catch {
               print("ERROR: Failed to delete - \(error)")
               }
          }
          
      case .delegate:
          return .none
      }
    }
  }
}
