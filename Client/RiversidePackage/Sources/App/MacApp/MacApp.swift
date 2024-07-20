import CloudSyncState
import CoreData
import Dependencies
import Entities
import FlashClient
import ForegroundRefreshState
import LicensesFeature
import Logging
import LogFeature
import MacRootFeature
import SystemNotification
import SwiftUI
import Utilities

@MainActor
public struct MacApp: App {
    private let cloudSyncState: CloudSyncState = .init()
    private let foregroundRefreshState: ForegroundRefreshState = .init()
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
                .environment(foregroundRefreshState)
                .environment(\.managedObjectContext, persistentProvider.viewContext)
                .systemNotification(context)
            
        }
        .commands {
            CommandGroup(after: .appSettings) {
                Button("Licenses") {
                    openWindow(id: "window-licenses")
                }
                
                if !Bundle.main.isProduction {
                    Button("Debug Log") {
                        openWindow(id: "window-debug-log")
                    }
                }
            }
        }
        
        Window(Text("Licenses"), id: "window-licenses") {
            LicensesScreen()
        }
        Window(Text("Debug Log"), id: "window-debug-log") {
            LogScreen()
        }
    }
}
