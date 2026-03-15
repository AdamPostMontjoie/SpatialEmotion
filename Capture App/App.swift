//
//  Capture_AppApp.swift
//  Capture App
//
//  Created by Adam Post-Montjoie on 3/6/26.
//

import SwiftUI
import ComposableArchitecture

@main
struct FoodSizer: App {
    
    static let store = Store(initialState: ContactsFeature.State()) {
        ContactsFeature()
      }
    var body: some Scene {
        WindowGroup {
            ContactsView(store:FoodSizer.store)
        }
    }
}
