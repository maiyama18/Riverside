import FeedsFeature
import NavigationState
import SwiftUI

struct MainTabScreen: View {
    @Environment(NavigationState.self) private var navigationState

    var body: some View {
        TabView(selection: navigationState.mainTab) {
            Group {
                Text("Stream")
                    .tabItem {
                        Label("Stream", systemImage: "dot.radiowaves.up.forward")
                    }
                    .tag(MainTab.stream)

                
                FeedsScreen()
                    .tabItem {
                        Label("Feeds", systemImage: "square.stack")
                    }
                    .tag(MainTab.feeds)

                Text("Settings")
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .tag(MainTab.settings)
            }
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        }
    }
}
