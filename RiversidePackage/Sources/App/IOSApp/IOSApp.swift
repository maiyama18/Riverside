import CloudSyncState
import Models
import NavigationState
import SwiftData
import SwiftUI

@MainActor
public struct IOSApp: App {
    private let navigationState = NavigationState()
    private let cloudSyncState = CloudSyncState()

    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            MainTabScreen()
                .environment(cloudSyncState)
                .environment(navigationState)
                .modelContainer(for: FeedModel.self)
        }
    }
}
