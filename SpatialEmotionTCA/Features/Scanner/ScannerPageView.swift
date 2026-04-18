import SwiftUI
import ComposableArchitecture

struct ScannerPageView: View {
    @Bindable var store: StoreOf<ScannerPageFeature>
    
    var body: some View {
        // The NavigationStack is the "Hallway" for this specific tab
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            
            // 1. The Root: The camera is permanently scoped to this tab
            CameraView(
                store: store.scope(state: \.camera, action: \.camera)
            )
            // Hides the top navigation bar so the camera can be full screen
            .toolbar(.hidden, for: .navigationBar)
            
        } destination: { store in
            // 2. The Destinations: Where the hallway leads
            switch store.case {
            case let .scanReview(reviewStore):
                ScanReviewView(store: reviewStore)
            }
        }
    }
}
