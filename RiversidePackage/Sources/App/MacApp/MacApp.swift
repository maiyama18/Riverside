import CloudSyncState
import Dependencies
import FlashClient
import LicensesFeature
import Models
import RootFeature
import SystemNotification
import SwiftData
import SwiftUI

@MainActor
public struct MacApp: App {
    private let cloudSyncState: CloudSyncState = .init()
    
    @Dependency(\.flashClient) private var flashClient
    
    @Environment(\.openWindow) private var openWindow
    
    @StateObject private var context: SystemNotificationContext
    
    public init() {
        let context = SystemNotificationContext()
        self._context = .init(wrappedValue: context)
        
        flashClient.injectContext(context)
    }
    
    public var body: some Scene {
        WindowGroup {
            RootScreen()
                .environment(cloudSyncState)
                .modelContainer(for: FeedModel.self)
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
