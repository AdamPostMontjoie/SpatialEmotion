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
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            List {
                ForEach(store.scans) { scan in
                    HStack {
                        NavigationLink(state: ScanReviewFeature.State(scanId: scan.id,
                                                                      objURL: scan.objURL,
                                                                      faceURL: scan.faceURL, emotion:scan.emotion))
                        {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(scan.name)  \(scan.emoji)")
                                    .font(.headline)
                                
                                // first 8 uuid characters
                                Text("ID: \(scan.id.uuidString.prefix(6))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // "d" - The Delete Button
                       Button(action: {
                            store.send(.deleteButtonTapped(id: scan.id))
                        }) {
                            // Using Apple's built-in vector icons
                            Image(systemName: "trash")
                        }
                        .foregroundColor(.red)
                        .buttonStyle(.borderless)
                       
                    }
                }
            }
            .navigationTitle("Scan History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarVisibility(.visible, for: .tabBar)
            // Alerts
            
            .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
            .onAppear {
                store.send(.onAppear)
            }
        }
        destination: { store in
                
                ScanReviewView(store: store)
            }
    }
}

