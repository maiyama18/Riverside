import BackgroundRefreshUseCase
import CloudSyncState
import Dependencies
@preconcurrency import Entities
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
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    @Dependency(\.backgroundRefreshUseCase) private var backgroundRefreshUseCase
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
                    await backgroundRefreshUseCase.schedule()
                }
                .onOpenURL { url in
                    guard url.scheme == "riverside" else { return }
                    switch url.host() {
                    case "stream":
                        Task {
                            try? await Task.sleep(for: .seconds(0.5))
                            navigationState.dismissSafariIfNeeded()
                            navigationState.mainTab = .stream
                        }
                    default:
                        break
                    }
                }
        }
        .backgroundTask(.appRefresh(backgroundRefreshUseCase.taskIdentifier)) {
            let context = persistentProvider.backgroundContext
            await backgroundRefreshUseCase.execute(context, cloudSyncState.eventDebouncedPublisher)
        }
    }
}
