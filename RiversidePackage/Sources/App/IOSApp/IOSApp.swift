import CloudSyncState
import CoreData
import Dependencies
import Entities
import Logging
import NavigationState
import SystemNotification
import SwiftUI

@MainActor
public struct IOSApp: App {
    private let navigationState = NavigationState()
    private let cloudSyncState = CloudSyncState()
    private let persistentProvider = PersistentProvider.cloud
    
    @Dependency(\.flashClient) private var flashClient
    @Dependency(\.logger[.app]) private var logger
    
    @StateObject private var context: SystemNotificationContext

    public init() {
        let context = SystemNotificationContext()
        self._context = .init(wrappedValue: context)
        
        self.flashClient.injectContext(context)
        
        logger.notice("app started")
    }
    
    public var body: some Scene {
        WindowGroup {
            MainTabScreen()
                .environment(cloudSyncState)
                .environment(navigationState)
                .environment(\.managedObjectContext, persistentProvider.viewContext)
                .systemNotification(context)
        }
    }
}
