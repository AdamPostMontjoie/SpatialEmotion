//
//  ScanReviewView.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/22/26.
//

import SwiftUI
import ComposableArchitecture

struct ScanReviewView: View {
    let store: StoreOf<ScanReviewFeature>
    var body: some View {
        VStack(spacing: 30) {
            Text("3D Scans Captured!")
                .font(.title)
                .fontWeight(.bold)
            
            if let faceNode = store.faceNode {
                FaceView(faceNode: faceNode)
                    .frame(height: 300)
                    .cornerRadius(12)
            } else {
                // loading spinner
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading Face Scan...")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
                .frame(height: 300) // Keep the same height so the UI doesn't violently jump when it loads
            }
            // ---------------------------
            VStack(spacing: 30) {
                Text("3D Scans Captured!")
                    .font(.title)
                    .fontWeight(.bold)
                
                if let objNode = store.objNode {
                    ObjectView(objectNode: objNode)
                        .frame(height: 300)
                        .cornerRadius(12)
                } else {
                    // loading spinner
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
                    Button("Delete Scan") { store.send(.deleteButtonTapped) }
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Review Scan")
            .navigationBarTitleDisplayMode(.inline)
            // start and stop scans/extraction
            .onAppear {
                store.send(.onAppear)
            }
            .onDisappear {
                store.send(.onDisappear)
            }
        }
    }
}
