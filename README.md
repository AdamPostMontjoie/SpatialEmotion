Temporary architectural notes
- 
Rendering of Scenes
- 
 The .merge in the ScanReviewFeature reducer kicks off two .runs that await the parsing of the face and objects in the background by handing them the urls. These scans, when they are loaded (whichever finishes first), pass a pointer to the new Scene we just created back to the reducer. The reducer then passes that pointer to the UIViewRepresentable for the scan. The UIViewRepresentable then creates a camera, and lets ScanReviewFeature know it's ready to be displayed. At that point, the loading spinner for the scan is replaced with the UIViewRepresentable. We also attach a cancelable id to the pointers to the scenes, and we destroy all UIViewRepresentables and Scenes rendered or currently rendering on disappear.
