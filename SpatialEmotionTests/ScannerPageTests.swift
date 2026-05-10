//
//  ScannerPageFea.swift
//  SpatialEmotion
//
//  Created by Adam Post-Montjoie on 5/9/26.
//

import ComposableArchitecture
import XCTest
@testable import SpatialEmotion
import ARKit


@MainActor
final class ScannerPageTests: XCTestCase {
    func testWelcome() async {
        
        let store = TestStore(initialState: ScannerPageFeature.State(
            completedWelcome:false
        )) {
            ScannerPageFeature()
        }
        await store.send(.onAppear) {
            $0.camera.currentMode = .off
            $0.destination = .alert(.welcome())
        }
        await store.send(.destination(.presented(.alert(.finishedWelcome)))){
            $0.$completedWelcome.withLock {$0 = true}
            $0.destination = nil
        }
        await store.receive(\.camera.onAppear){
            $0.camera.currentMode = .lidar
        }
    }
    func testScanReview() async {
        let store = TestStore(initialState:ScannerPageFeature.State()){
            ScannerPageFeature()
        }
        let mockMeshURL = URL(string: "file://mock-mesh-path.usdz")!
        let mockFaceURL = URL(string: "file://mock-face-path.usdz")!
        let mockUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        await store.send(.camera(.delegate(.scanSavedToDb(scanId: mockUUID, objUrl: mockMeshURL, faceUrl: mockFaceURL, emotion: "Sadness"))))  {
            let newReviewScreen = ScanReviewFeature.State(
                            scanId: mockUUID,
                            objURL: mockMeshURL,
                            faceURL: mockFaceURL,
                            emotion: "Sadness"
                        )
            $0.path.append(.scanReview(newReviewScreen))
        }
    }
    func testSelfDelete() async {
        let mockMeshURL = URL(string: "file://mock-mesh-path.usdz")!
        let mockFaceURL = URL(string: "file://mock-face-path.usdz")!
        let mockUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        
        let reviewState = ScanReviewFeature.State(
            scanId: mockUUID,
            objURL: mockMeshURL,
            faceURL: mockFaceURL,
            emotion: "Sadness"
        )
        
        let store = TestStore(initialState: ScannerPageFeature.State(
            path: StackState([.scanReview(reviewState)])
        )) {
            ScannerPageFeature()
        }
        await store.send(.path(.element(id: 0, action: .scanReview(.delegate(.scanRemoved(mockUUID)))))){
            $0.camera.currentMode = .lidar
            $0.camera.savedMeshUrl = nil
            $0.camera.savedFaceUrl = nil
            $0.camera.detectedEmotion = nil
            $0.path.removeAll()
        }
    }
    
    func testBackout() async {
            let mockMeshURL = URL(string: "file://mock-mesh-path.usdz")!
            let mockFaceURL = URL(string: "file://mock-face-path.usdz")!
            let mockUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
            
            let reviewState = ScanReviewFeature.State(
                scanId: mockUUID,
                objURL: mockMeshURL,
                faceURL: mockFaceURL,
                emotion: "Sadness"
            )
            
            let store = TestStore(initialState: ScannerPageFeature.State(
                path: StackState([.scanReview(reviewState)])
            )) {
                ScannerPageFeature()
            }
            
            await store.send(.path(.popFrom(id: 0))) {
                $0.camera.currentMode = .lidar
                $0.camera.savedMeshUrl = nil
                $0.camera.savedFaceUrl = nil
                
                $0.path.removeAll()
            }
        }
    
}
