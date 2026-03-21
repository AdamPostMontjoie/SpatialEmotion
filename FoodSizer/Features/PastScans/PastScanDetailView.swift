//
//  PastScanDetailView.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/21/26.
//

import SwiftUI
import ComposableArchitecture

struct PastScanDetailView: View {
    // We use 'let' here instead of '@Bindable var' because we are only
    // reading data and sending discrete actions (buttons).
    // You only need @Bindable for two-way bindings (like a TextField).
    let store: StoreOf<PastScanDetailFeature>
    
    var body: some View {
        VStack(spacing: 20) {
            Text(store.name)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button {
                store.send(.nameTapped)
            } label: {
                Text("Tap Me")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .navigationTitle("Scan Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PastScanDetailView(
            store: Store(initialState: PastScanDetailFeature.State()) {
                PastScanDetailFeature()
            }
        )
    }
}
