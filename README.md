# Spatial Emotion (iOS / Swift 6 / TCA)

An iOS application that captures the moment in 3D, and how it made you feel, built with The Composable Architecture. 

<!-- ABOUT THE PROJECT -->
## About The Project

(gif here)

Spatial Emotion is an experimental iOS application that uses an iPhone's LiDAR and TrueDepth scanners to map a user's physical location and the shape and emotion of their face in that moment.

The scanning is split into 2 phases. 
1. **Environment Mapping:** The `LiDARClient` utilizes `ARWorldTrackingConfiguration` to extract `ARMeshAnchor`s, generating a high-fidelity 3D map of the user's surroundings. 
2. **Emotion Tracking:** The app transitions to the TrueDepth camera, processing `ARFaceAnchor.blendShapes` to determine emotion mid scan. These facial mappings are put through a classification algorithm in order to display an emoji anchored to the user's forehead so they are given feedback as to what is currently being captured.

After each scan, the `ARAnchor`s are used to build `.usdz` files and are then saved to the SSD. Once both are complete, a scan object containing file URLs and metadata is saved to SwiftData. The user can then view and interact with their scans extracted from the `.usdz` files as SceneKit `SCNView`s, which are emotionally color coded. They can also browse a history of their past scans.

### Built With

* The Composable Architecture
* Swift 6
* SwiftUI
* RealityKit (Display of Emoji, LiDAR 3d mesh)
* ARKit (TrueDepth and LiDAR scanning and data manipulation)
* SceneKit (Rendering of interactable 3d displays)
* SwiftData (Storage of scan pointers)

## Technical Highlights
- **Delayed `ARSession` transition:** When a user triggered a scan, the `LiDARClient` would capture the scene, save it to disk, and pass the URL to the app state. However, switching the camera state directly from LiDAR to Face tracking caused occasional crashes because the LiDAR configuration wasn't fully dismantled by the `ARView` before the Face configuration attempted to build. To fix this, I implemented a deliberate `CameraMode.off` state transition with an asynchronous delay. This safely pauses the active session, clears the buffers, and allows the hardware to fully reset before spinning up the `FaceClient`. Both URLs were then safely paired and persisted to SwiftData. This .off state also became useful to pause the `ARSession` when it was not visible to save memory.

- **Removal of `unchecked @Sendable`:** Originally, the `ARSession` was being passed directly to the TCA state so I could pass it into the LiDAR and Face dependencies that extract the `ARAnchor` data and return URLs linking to the `.usdz` files. This was dangerous behavior, increased the risk of the dependencies extracting the anchors at the wrong time, and also made the entire camera state untestable. By removing this and instead letting the `ARSessionDelegate` handle the dependencies and only giving state back the URLs, I fixed all of these issues. I realized after that refactoring the dependencies to accept just the anchors as an argument would increase testability and would not require the use of `unchecked @Sendable`, so I plan to make that change later.

- **Improved Scene Loading** To guarantee the main thread remains unblocked when parsing heavy .usdz files from the SSD, the ScanReviewFeature reducer leverages TCA's .merge to kick off concurrent .run tasks. The face and object nodes are extracted from storage on a background thread and once parsed, the nodes are sent back to the main thread, updating the state pointer. This state update triggers the `UIViewRepresentable` to instantiate a new `SCNScene`, map the camera, and swap out the loading spinner for the fully rendered 3D mesh. This allows them to load in whenever they're ready instead of waiting for the other to finish.

## Planned Features
- Custom Metal Shading Language on the `SCNViews` for more emotional distinction
- Improved emotional accuracy
- Select and delete all from history
- TCA testing (and putting usdz clients back in state)

## Known Issues
- ARSession Crashes: rarer but still present, more elegant handling needed
- Usdz files inaccessible on rebuild
