//
//  ScanHistoryTests.swift
//  SpatialEmotion
//
//  Created by Adam Post-Montjoie on 5/10/26.
//

import ComposableArchitecture
import XCTest
@testable import SpatialEmotion
import ARKit


@MainActor
final class ScanHistoryTests: XCTestCase {
    func testPopulationFromDatabase() async {
            let mockUUID1 = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
            let mockDate = Date(timeIntervalSince1970: 0)
            
            // Mock the already-mapped struct that the client returns
            let mockScans = [
                PairedScan(
                    id: mockUUID1,
                    name: "Scan 1",
                    timestamp: mockDate,
                    objURL: URL(string: "file://docs/obj1.usdz")!,
                    faceURL: URL(string: "file://docs/face1.usdz")!,
                    emotion: "HAPPINESS",
                    emoji: "😀"
                )
            ]
            
            let store = TestStore(initialState: ScanHistoryFeature.State()) {
                ScanHistoryFeature()
            } withDependencies: {
                $0.databaseClient.fetchAllSessions = { return mockScans }
            }
            
            await store.send(.onAppear)
            
            await store.receive(\.scansLoaded) {
                $0.scans = IdentifiedArray(uniqueElements: mockScans)
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
        let store = TestStore(initialState: ScanHistoryFeature.State(
            path: StackState([reviewState])
        )) {
            ScanHistoryFeature()
        }
        await store.send(.path(.element(id: 0, action: .delegate(.scanRemoved(mockUUID)))))
        await store.receive(\.successAlert){
            $0.destination = .alert(.deletionSuccess())
        }
        await store.send(.destination(.dismiss)){
            $0.destination = nil
        }
    }
    func testDeleteFailure() async {
        let mockMeshURL = URL(string: "file://mock-mesh-path.usdz")!
        let mockFaceURL = URL(string: "file://mock-face-path.usdz")!
        let mockUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        struct MockError: Error {}
        let reviewState = ScanReviewFeature.State(
            scanId: mockUUID,
            objURL: mockMeshURL,
            faceURL: mockFaceURL,
            emotion: "Sadness"
        )
        let store = TestStore(initialState: ScanHistoryFeature.State(
            path: StackState([reviewState])
        )) {
            ScanHistoryFeature()
        } withDependencies: {
            $0.databaseClient.deleteSession = { _, _, _ in
                            throw MockError()
                        }
        }
        await store.send(.path(.element(id: 0, action: .delegate(.scanFailedToRemove))))
        {
            $0.destination = .alert(.deletionFailure())
        }
        await store.send(.destination(.dismiss)){
            $0.destination = nil
        }
    }
}
