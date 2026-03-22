//
//  ScanHistoryView.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/21/26.
//

import SwiftUI
import ComposableArchitecture

struct ScanHistoryView: View {
    @Bindable var store: StoreOf<ScanHistoryFeature>
    
    var body: some View {
        // 1. The Hallway (NavigationStack)
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            List {
                ForEach(store.scans) { scan in
                    HStack {
                        // "l" - The Link
                        NavigationLink(state: PastScanDetailFeature.State(name: scan.name)) {
                            Text("l - \(scan.name)")
                        }
                        
                        Spacer()
                        
                        // "d" - The Delete Button
                        Button("d") {
                            // Make sure you add this action to your Reducer!
                            store.send(.deleteButtonTapped(id: scan.id))
                        }
                        .foregroundColor(.red)
                        .buttonStyle(.borderless)
                    }
                }
            }
            .navigationTitle("History")
            // 2. The Dial (Alerts)
            .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
            
        }
        destination: { store in
                // 3. The Destination (Where the hallway leads)
                // Swift automatically knows this 'store' belongs to PastScanDetailFeature
                PastScanDetailView(store: store)
            }
    }
}

#Preview {
    ScanHistoryView(
        store: Store(
            initialState: ScanHistoryFeature.State(
                scans: [
                    PastScan(id: UUID(), name: "Apple", info: 150),
                    PastScan(id: UUID(), name: "Bowl of Rice", info: 350)
                ]
            )
        ) {
            ScanHistoryFeature()
        }
    )
}
