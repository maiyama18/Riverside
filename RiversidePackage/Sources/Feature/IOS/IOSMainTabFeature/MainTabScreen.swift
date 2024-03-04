import AppAppearanceClient
import CoreData
import Dependencies
import Entities
import NavigationState
import Utilities
import IOSFeedsFeature
import IOSSafariFeature
import IOSSettingsFeature
import IOSStreamFeature
import SwiftUI
import ViewModifiers
import WidgetKit

@MainActor
public struct MainTabScreen: View {
    @AppStorage("appearance") private var appearance: UIUserInterfaceStyle = .unspecified
    
    @Dependency(\.appAppearanceClient) private var appAppearanceClient
    
    @Environment(NavigationState.self) private var navigationState
    
    @FetchRequest(fetchRequest: EntryModel.unreads) private var unreadEntries: FetchedResults<EntryModel>
    
    @State private var loadingAllFeedsOnForeground: Bool = false
    
    public init() {}

    public var body: some View {
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
        .onChange(of: appearance, initial: true) { _, appearance in
            appAppearanceClient.apply(appearance)
        }
        .onChange(of: unreadEntries.map(\.url), initial: false) { _, _ in
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: navigationState.safariContent, initial: false) { _, safariContent in
            if let safariContent {
                showSafari(url: safariContent.url, onDisappear: safariContent.onDisappear)
            } else {
                dismissSafari()
            }
        }
        .addNewEntriesForAllFeedsOnForeground(loading: $loadingAllFeedsOnForeground)
        .deleteDuplicatedEntriesOnBackground()
        .environment(\.loadingAllFeedsOnForeground, loadingAllFeedsOnForeground)
    }
}

