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
                Text("A moment of \(store.emotion)")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                if let faceNode = store.faceNode {
                    FaceView(faceNode: faceNode, faceColor: EmotionalColor(store.emotion))
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
                    Text("The place where it happened")
                        .font(.title)
                        .fontWeight(.bold)
                    
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

func EmotionalColor(_ emotion:String) -> UIColor{
    switch emotion{
    case "happiness":
        return .systemYellow
    case "sadness":
        return .systemBlue
    case "anger":
        return .systemRed
    case "IShowSpeed":
        return .systemGreen
    case "neutrality":
        return .systemGray
    case "unknown":
        return .systemMint
    case "suprise":
        return .systemPink
    default:
        return .black
    }
}
