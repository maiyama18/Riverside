import CloudSyncState
import Dependencies
import Entities
import Models
import NavigationState
import SystemNotification
import SwiftData
import SwiftUI

@MainActor
public struct IOSApp: App {
    private let navigationState = NavigationState()
    private let cloudSyncState = CloudSyncState()
    private let persistentProvider = PersistentProvider.cloud
    
    @Dependency(\.flashClient) private var flashClient
    
    @StateObject private var context: SystemNotificationContext

    public init() {
        let context = SystemNotificationContext()
        self._context = .init(wrappedValue: context)
        
        self.flashClient.injectContext(context)
    }
    
    public var body: some Scene {
        WindowGroup {
            MainTabScreen()
                .environment(cloudSyncState)
                .environment(navigationState)
                .environment(\.managedObjectContext, persistentProvider.viewContext)
                .modelContainer(for: FeedModel.self)
                .systemNotification(context)
        }
    }
}
