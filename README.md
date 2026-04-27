#  Temporary architectural notes and stories so I remember (Polishing Soon w GIF)

### In Progress
- Removal of @Unchecked arsession for safer trigger pattern
- Metal Shading
- Tab switch teardowns
- UI stuff

###  Swapping from lidar to faceid and saving data.
(while doing this, the AR view is using a coordinator to let the state know if there is any mesh ready. This allows us to disable scanning until there is something to be scanned)
In order to switch the RealityKit ARViewContainer from ARWorldTrackingConfiguration to ARFaceTrackingConfiguration, we need to hold onto the state of the camera. When the user clicks the button and the LiDARClient saves the scene and passes through the URL, we hold that URL in state (need to add way to destroy stored scans on incomplete scan/interruption) and send that the scan was completed. We then have to switch from lidar to face, but here is where I **encountered a bug**. I was switching camera state directly from lidar to face, and so occasionally the lidar was not able to be completely removed from the ARView before the configuration for face began to build, and thus a crash. This was fixed by adding a small pause where the ARView session was paused before the face client was allowed to be configured. Once the user clicks scan again, and the FaceClient creates a new scene and saves to storage, it passes through the URL. Now that we have both URLs, we are able to save both of them to SwiftData. 

###  Rendering of Scenes 
 The .merge in the ScanReviewFeature reducer kicks off two .runs that await the extraction of the face and object nodes in the background by handing them the urls. These scan nodes, when they are extracted from storage and unwrapped from the usdz files, are sent by the reducer back to the main thread. The reducer then saves that pointer to state, which lets the UIViewRepresentable know that it's time to create a new scene. The UIViewRepresentable then creates a new scene and adds the node and a camera, and lets ScanReviewFeature know it's ready to be displayed. At that point, the loading spinner for the scan is replaced with the UIViewRepresentable. We also attach a cancelable id to the pointers to the scenes, and we destroy all UIViewRepresentables and Scenes rendered or currently rendering on disappear.




