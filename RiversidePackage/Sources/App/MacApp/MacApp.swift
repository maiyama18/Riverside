import CloudSyncState
import CoreData
import Dependencies
import Entities
import FlashClient
import LicensesFeature
import Logging
import MacRootFeature
import SystemNotification
import SwiftUI

@MainActor
public struct MacApp: App {
    private let cloudSyncState: CloudSyncState = .init()
    private let persistentProvider: PersistentProvider = .cloud
    
    @Dependency(\.flashClient) private var flashClient
    @Dependency(\.logger[.app]) private var logger
    
    @Environment(\.openWindow) private var openWindow
    
    @StateObject private var context: SystemNotificationContext
    
    public init() {
        let context = SystemNotificationContext()
        self._context = .init(wrappedValue: context)
        
        flashClient.injectContext(context)
        
        logger.notice("app started")
    }
    
    public var body: some Scene {
        WindowGroup {
            RootScreen()
                .environment(cloudSyncState)
                .environment(\.managedObjectContext, persistentProvider.viewContext)
                .systemNotification(context)
            
        }
        .commands {
            CommandGroup(after: .appSettings) {
                Button("Licenses") {
                    openWindow(id: "window-licenses")
                }
            }
        }
        
        Window(Text("Licenses"), id: "window-licenses") {
            LicensesScreen()
        }
    }
}
