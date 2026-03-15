//
//  AppFeatureTests.swift
//  FoodSizer
//
//  Created by Adam Post-Montjoie on 3/7/26.
//
import ComposableArchitecture
import XCTest
@testable import Capture_App

@MainActor
final class AppFeatureTests: XCTestCase {
  func testIncrementInFirstTab() async {
      let store = TestStore(initialState: AppFeature.State()) {
          AppFeature()
      }
      await store.send(./tab1.incrementButtonTapped){
          $0.tab1.count = 1
      }
  }
    
    
    
}

