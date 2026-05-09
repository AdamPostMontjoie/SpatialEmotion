//
//  ScanReviewView.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/22/26.
//

import SwiftUI
import ComposableArchitecture

struct ScanReviewView: View {
    @Bindable var store: StoreOf<ScanReviewFeature>
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("Emotion: \(store.emotion)")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                if let faceNode = store.faceNode {
                    FaceView(faceNode: faceNode, faceColor: EmotionClassification().EmotionalColor(store.emotion))
                        .frame(height: 300)
                        .cornerRadius(12)
                        .padding(.horizontal)
                } else {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading Face Scan...")
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                    .frame(height: 300)
                }
                
                VStack(spacing: 30) {
                    Text("Where it happened")
                        .font(.title)
                        .fontWeight(.bold)
                    if store.emotion == "IShowSpeed" {
                        Image("speed") // Replace with your exact Asset catalog name
                            .resizable()
                            .scaledToFill()
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(12)
                    } else {
                        if let objNode = store.objNode {
                            ObjectView(objectNode: objNode)
                                .frame(height: 300)
                                .cornerRadius(12)
                        } else {
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Loading Object Scan...")
                                    .foregroundColor(.gray)
                                    .padding(.top, 8)
                            }
                            .frame(height: 300)
                        }
                    }
                    
                    
                    HStack(spacing: 30) {
                        Button("Delete Scan") { store.send(.deleteButtonTapped(store.scanId)) }
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Review Scan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .alert($store.scope(state: \.alert, action: \.alert))
        .onAppear {
            store.send(.onAppear)
        }
    }
}


