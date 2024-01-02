import FeedsFeature
import NavigationState
import SettingsFeature
import StreamFeature
import SwiftUI

@MainActor
struct MainTabScreen: View {
    @Environment(NavigationState.self) private var navigationState

    var body: some View {
        @Bindable var navigationState = navigationState
        
        TabView(selection: $navigationState.mainTab) {
            Group {
                StreamScreen()
                    .tabItem {
                        Label("Stream", systemImage: "dot.radiowaves.up.forward")
                    }
                    .tag(MainTab.stream)

                
                FeedsScreen()
                    .tabItem {
                        Label("Feeds", systemImage: "square.stack")
                    }
                    .tag(MainTab.feeds)

                SettingsScreen()
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
