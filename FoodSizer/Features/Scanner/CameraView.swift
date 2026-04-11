//
//  CameraView.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/22/26.
//

import SwiftUI
import ComposableArchitecture

struct CameraView:View {
    @Bindable var store: StoreOf<CameraFeature>
    
    var body: some View {
        ZStack {
            ARViewContainer(
                onSessionCreated: { session in
                    store.send(.sessionCreated(session))
                },
                currentMode: store.currentMode,
                onReadyStateChanged:{ isReady in
                    store.send(.readyStateChanged(isReady:isReady))
                })
                
                .ignoresSafeArea()
            VStack {
                Spacer()
                
                Button {
                    store.send(.scanButtonTapped)
                } label: {
                    Text(store.currentMode == .lidar ? "Scan Object":"Scan Face")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(store.isReadyToScan ? Color.blue: Color.gray)
                        .cornerRadius(16)
                }
                .disabled(!store.isReadyToScan)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
        }
    }
}
