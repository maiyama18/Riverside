import AddNewEntriesUseCase
import AppAppearanceClient
import CoreData
import DeleteDuplicatedEntriesUseCase
import Dependencies
import Entities
import IOSFeedsFeature
import NavigationState
import Utilities
import IOSSettingsFeature
import IOSStreamFeature
import SwiftUI

@MainActor
struct MainTabScreen: View {
    @AppStorage("appearance") private var appearance: UIUserInterfaceStyle = .unspecified
    
    @Dependency(\.appAppearanceClient) private var appAppearanceClient
    @Dependency(\.addNewEntriesUseCase) private var addNewEntriesUseCase
    
    @Environment(NavigationState.self) private var navigationState
    @Environment(\.managedObjectContext) private var context

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
        .onForeground { @MainActor in
            do {
                try await addNewEntriesUseCase.executeForAllFeeds(context, false)
            } catch {
                print(error)
            }
        }
        .onChange(of: appearance, initial: true) { _, appearance in
            appAppearanceClient.apply(appearance)
        }
        .deleteDuplicatedEntriesOnce()
    }
}
