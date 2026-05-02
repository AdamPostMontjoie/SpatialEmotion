//
//  CameraView.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/22/26.
//

import SwiftUI
import ComposableArchitecture

struct CameraView: View {
    @Bindable var store: StoreOf<CameraFeature>
    @State var liveEmotion:String?
    var emotionClass:EmotionClassification = EmotionClassification()
    var body: some View {
        ZStack {
            //we can let the arviewcontainer deal with the face and lidar dependencies
            //when it is ready, it will store.send url and emotion to the camerafeature
            //will make testability of face and lidar client difficult/impossible
            if store.currentMode != .off {
                ARViewContainer(
                    saveSessionNow:store.isSaving,
                    currentMode: store.currentMode,
                    onCaptureAnchors: { anchies in
                        store.send(.captureAnchors(anchies))
                    },
                    onReadyStateChanged:{ isReady in
                        store.send(.readyStateChanged(isReady:isReady))
                    }
                    
                )
                .ignoresSafeArea()
                .transition(.opacity)
                
            }
            
            if store.currentMode == .off {
                ZStack {
                    // iOS Frosted Glass Effect
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Configuring Sensors...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                .transition(.opacity)
            }

            VStack {
                Spacer()
                
                Button {
                    store.send(.scanButtonTapped)
                } label: {
                    Text(store.currentMode == .lidar ? "Capture Surroundings" : "Capture Emotion")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(store.isReadyToScan ? Color.blue : Color.gray)
                        .cornerRadius(16)
                }
                .disabled(!store.isReadyToScan)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        //  The magic line: Tells the ZStack to crossfade changes smoothly
        .animation(.easeInOut(duration: 0.3), value: store.currentMode)
        .onAppear {
            store.send(.onAppear)
        }
        .onDisappear{
            store.send(.onDisappear)
        }
    }
}


