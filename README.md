# Spatial Emotion (iOS / Swift 6 / TCA)

An iOS application that captures the moment in 3D, and how it made you feel, built with The Composable Architecture. Extracts 3D environment meshes and facial data with the LiDAR and TrueDepth scanners and ARKit, and uses SceneKit to let the user view and interact with them.

*(Note: Full UI polish and demo GIF and more notes coming soon. Currently refining)*

## Architecture & Engineering Notes

### 1. Hardware State Transitions & Race Conditions
Switching the `ARViewContainer` from an `ARWorldTrackingConfiguration` (LiDAR) to an `ARFaceTrackingConfiguration` created a race condition. When a user triggered a scan, the `LiDARClient` would capture the scene, save it to disk, and pass the URL to the app state. However, switching the camera state directly from LiDAR to Face tracking caused occasional crashes because the LiDAR configuration wasn't fully dismantled by the `ARView` before the Face configuration attempted to build. 
* **The Fix:** Implemented a deliberate `CameraMode.off` state transition with an asynchronous delay. This safely pauses the active session, clears the buffers, and allows the hardware to fully reset before spinning up the `FaceClient`. Both URLs are then safely paired and persisted to SwiftData.

### 2. Concurrent Scene Rendering & Threading
To prevent the main thread from blocking while parsing heavy `.usdz` files from the SSD, the `ScanReviewFeature` reducer leverages TCA's `.merge` to kick off concurrent `.run` tasks.
* The face and object nodes are extracted from storage on a background thread.
* Once parsed, the nodes are sent back to the main thread, updating the state pointer.
* This state update triggers the `UIViewRepresentable` to instantiate a new `SCNScene`, map the camera, and swap out the loading spinner for the fully rendered 3D mesh.


## Current Roadmap
- [ ] **State Isolation:** Complete the removal of `@unchecked Sendable` from the ARSession by properly isolating the session delegate loop.
- [ ] **Memory Teardowns:** Finalize the navigation path stack-clearing logic on tab switches to prevent background SceneKit rendering.
- [ ] **Graphics Pipeline:** Inject custom Metal Shading Language (MSL) via `SCNShadable` to dynamically warp face mesh vertices based on biometric emotion data.
- [ ] **UI/UX:** Finalize the SwiftUI layout for pretty
