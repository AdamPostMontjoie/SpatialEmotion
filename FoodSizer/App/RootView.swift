import SwiftUI
import ComposableArchitecture

struct RootView: View {
    @Bindable var store: StoreOf<RootFeature>
    
    var body: some View {
        // TabView automatically handles switching screens safely
        TabView(selection: $store.selectedTab.sending(\.selectedTab)) {
            
            // TAB 1: The Camera Placeholder (For tomorrow)
            VStack(spacing: 20) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                Text("Scanner Coming Soon...")
                    .font(.headline)
            }
            .tabItem {
                Label("Scanner", systemImage: "camera")
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
