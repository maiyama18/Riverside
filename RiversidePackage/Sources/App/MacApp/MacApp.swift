import CloudSyncState
import Models
import RootFeature
import SwiftData
import SwiftUI

@MainActor
public struct MacApp: App {
    private let cloudSyncState: CloudSyncState = .init()
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            RootScreen()
                .environment(cloudSyncState)
                .modelContainer(for: FeedModel.self)
        }
    }
}
