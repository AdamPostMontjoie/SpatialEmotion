import SwiftUI
import ComposableArchitecture

struct RootView: View {
    @Bindable var store: StoreOf<RootFeature>
    
    var body: some View {
        // TabView automatically handles switching screens safely
        TabView(selection: $store.selectedTab.sending(\.selectedTab)) {
            
            // TAB 1: The Camera Placeholder (For tomorrow)
            ScannerPageView(
                store: store.scope(state: \.scannerTab, action: \.scannerTab)
            )
            .tabItem {
                Label("Scanner", systemImage: "camera.viewfinder")
            }
            .tag(RootFeature.Tab.camera)
            
            // TAB 2: Your Working History List
            ScanHistoryView(
                store: store.scope(state: \.historyTab, action: \.historyTab)
            )
            .tabItem {
                Label("Past Scans", systemImage: "clock.arrow.circlepath")
            }
            .tag(RootFeature.Tab.history)
        }
    }
}

#Preview {
    RootView(
        store: Store(initialState: RootFeature.State()) {
            RootFeature()
        }
    )
}
