import BackgroundTasks
import CloudSyncState
import Dependencies
import Entities
import Logging
import NavigationState
import SystemNotification
import IOSMainTabFeature
import SwiftUI
import ViewModifiers

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
                .onBackground {
                    scheduleBackgroundRefresh()
                }
        }
        .backgroundTask(.appRefresh("com.muijp.RiversideIOSApp.refreshTask")) {
            await executeBackgroundRefresh()
        }
    }
    
    nonisolated private func scheduleBackgroundRefresh() {
        @Dependency(\.logger[.app]) var logger
        
        let request = BGAppRefreshTaskRequest(identifier: "com.muijp.RiversideIOSApp.refreshTask")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.error("scheduled background task")
        } catch {
            logger.error("failed to schedule background task: \(error, privacy: .public)")
        }
    }
    
    nonisolated private func executeBackgroundRefresh() async {
        @Dependency(\.logger[.app]) var logger
        
        for i in 1...5 {
            logger.notice("background print \(i)")
            try? await Task.sleep(for: .seconds(1))
        }
    }
}
