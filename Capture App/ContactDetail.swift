//
//  ContactDetail.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/15/26.
//

import ComposableArchitecture

@Reducer
struct ContactDetail{
    @ObservableState
    struct State:Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        let contact: Contact
    }
    enum Action {
            case alert(PresentationAction<Alert>)
            case delegate(Delegate)
            case deleteButtonTapped
            enum Alert {
              case confirmDeletion
            }
            enum Delegate {
              case confirmDeletion
            }
    }
    @Dependency(\.dismiss) var dismiss
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action{
            case .alert(.presented(.confirmDeletion)):
                return .run { send in
                  await send(.delegate(.confirmDeletion))
                  await self.dismiss()
                }
            case .alert:
                return .none
            case .delegate:
                return .none
            case .deleteButtonTapped:
                state.alert = .confirmDeletion
                return .none
            }
            
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
extension AlertState where Action == ContactDetail.Action.Alert {
  static let confirmDeletion = Self {
    TextState("Are you sure?")
  } actions: {
    ButtonState(role: .destructive, action: .confirmDeletion) {
      TextState("Delete")
    }
  }
}
import SwiftUI

struct ContactDetailView: View {
    @Bindable var store: StoreOf<ContactDetail>
    var body: some View {
        Form {
            Button("Delete") {
                   store.send(.deleteButtonTapped)
                 }
        }
        .navigationBarTitle(Text(store.contact.name))
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}


#Preview {
  NavigationStack {
    ContactDetailView(
      store: Store(
        initialState: ContactDetail.State(
          contact: Contact(id: UUID(), name: "Blob")
        )
      ) {
        ContactDetail()
      }
    )
  }
}
