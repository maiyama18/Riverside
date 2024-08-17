import AppAppearanceClient
@preconcurrency import CoreData
import CloudSyncState
import Dependencies
import Entities
import ForegroundRefreshState
import FlashClient
import NavigationState
import Utilities
import IOSFeedsFeature
import IOSSettingsFeature
import IOSStreamFeature
import SwiftUI
import ViewModifiers
import WidgetKit

@MainActor
public struct MainTabScreen: View {
    @AppStorage("appearance") private var appearance: UIUserInterfaceStyle = .unspecified
    
    @Dependency(\.appAppearanceClient) private var appAppearanceClient
    @Dependency(\.flashClient) private var flashClient
    
    @Environment(\.managedObjectContext) private var context
    @Environment(CloudSyncState.self) private var cloudSyncState
    @Environment(NavigationState.self) private var navigationState
    @Environment(ForegroundRefreshState.self) private var foregroundRefreshState
    
    @FetchRequest(fetchRequest: EntryModel.unreads) private var unreadEntries: FetchedResults<EntryModel>
    
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
        .onForeground {
            Task {
                do {
                    try await foregroundRefreshState.refresh(context: context, cloudSyncState: cloudSyncState, force: false, timeout: .seconds(10))
                } catch {
                    await flashClient.present(
                        type: .error,
                        message: "Failed refresh feed: \(error.localizedDescription)"
                    )
                }
            }
        }
        .deleteDuplicatedEntriesOnBackground()
    }
}

