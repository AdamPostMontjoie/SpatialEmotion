import SwiftUI
import ComposableArchitecture

struct ScannerPageView: View {
    @Bindable var store: StoreOf<ScannerPageFeature>
    
    var body: some View {
        // The NavigationStack is the "Hallway" for this specific tab
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            CameraView(
                store: store.scope(state: \.camera, action: \.camera)
            )
            // Hides the top navigation bar so the camera can be full screen
            .toolbarVisibility(.hidden, for: .navigationBar)
            .toolbarVisibility(.visible, for: .tabBar)
            
        } destination: { store in
            switch store.case {
            case let .scanReview(reviewStore):
                ScanReviewView(store: reviewStore)
            }
        }
    }
}
