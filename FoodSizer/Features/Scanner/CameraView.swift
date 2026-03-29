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
                })
                .ignoresSafeArea()
            VStack {
                Spacer()
                
                Button {
                    store.send(.scanButtonTapped)
                } label: {
                    Text("Capture Scan")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(16)
                }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
        }
    }
}
