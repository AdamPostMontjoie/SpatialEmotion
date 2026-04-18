//
//  Capture_AppApp.swift
//  Capture App
//
//  Created by Adam Post-Montjoie on 3/6/26.
//

import SwiftUI
import ComposableArchitecture
import SwiftData

@main
struct FoodSizer: App {
    
    static let store = Store(initialState: RootFeature.State()) {
        RootFeature()
      }
    var body: some Scene {
        WindowGroup {
            RootView(store:FoodSizer.store)
        }
        .modelContainer(for: PairedScanSession.self) //initializes database for app
    }
}
