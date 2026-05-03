//
//  CameraFeatureTests.swift
//  SpatialEmotion
//
//  Created by Adam Post-Montjoie on 5/3/26.
//

import ComposableArchitecture
import XCTest
@testable import Capture_App
import ARKit


@MainActor
final class CameraFeatureTests: XCTestCase {
  func testScan() async {
      let mockMeshURL = URL(string: "file://mock-mesh-path.usdz")!
      let mockFaceURL = URL(string: "file://mock-face-path.usdz")!
      
      let mockUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
      
      let store = TestStore(initialState: CameraFeature.State()) {
        CameraFeature()
      } withDependencies: {
          $0.lidarClient.captureMesh = { _ in return mockMeshURL}
          $0.faceClient.captureFace = {_ in return (mockFaceURL, "happy")}
          $0.databaseClient.saveSession = { _, _, _, _ in }
        
          $0.uuid = .constant(mockUUID)
      }
      await store.send(.readyStateChanged(isReady: true)){
          $0.isReadyToScan = true
      }
      await store.send(.scanButtonTapped){
          $0.isSaving = true
      }
      let mockAnchors: [ARAnchor] = []
      await store.send(.captureAnchors(mockAnchors)) {
          $0.isSaving = false
      }
      await store.receive(\.scanCompleted) {
          $0.savedMeshUrl = mockMeshURL
          $0.isReadyToScan = false
      }
      await store.receive(\.setMode) {
          $0.currentMode = .off
      }
      await store.receive(\.setMode) {
          $0.currentMode = .face
      }
      await store.send(.readyStateChanged(isReady: true)){
          $0.isReadyToScan = true
      }
      await store.send(.scanButtonTapped){
          $0.isSaving = true
      }
      let mockFaceAnchors: [ARAnchor] = []
      await store.send(.captureAnchors(mockFaceAnchors)) {
          $0.isSaving = false
      }
      await store.receive(\.scanCompleted) {
          $0.savedFaceUrl = mockFaceURL
          $0.detectedEmotion = "happy"
          $0.currentMode = .off
          $0.isReadyToScan = false
      }
      await store.receive(\.saveToDataBase) {
          $0.savedMeshUrl = nil
          $0.savedFaceUrl = nil
          $0.detectedEmotion = nil
      }
      await store.receive(
                .delegate(.scanSavedToDb(
                    scanId: mockUUID,
                    objUrl: mockMeshURL,
                    faceUrl: mockFaceURL,
                    emotion: "happy"
                ))
            )
  }
}
