import AppAppearanceClient
import CoreData
import Dependencies
import FeedsFeature
import FeedUseCase
import NavigationState
import Utilities
import SettingsFeature
import StreamFeature
import SwiftData
import SwiftUI

@MainActor
struct MainTabScreen: View {
    @AppStorage("appearance") private var appearance: UIUserInterfaceStyle = .unspecified
    
    @Dependency(\.appAppearanceClient) private var appAppearanceClient
    @Dependency(\.feedUseCase) private var feedUseCase
    
    @Environment(NavigationState.self) private var navigationState
    @Environment(\.modelContext) private var context

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
        .deleteDuplicatedEntriesOnce()
        .onForeground { @MainActor in
            do {
                try await feedUseCase.addNewEpisodesForAllFeeds(context, false)
            } catch {
                print(error)
            }
        }
        .onChange(of: appearance, initial: true) { _, appearance in
            appAppearanceClient.apply(appearance)
        }
    }
}
