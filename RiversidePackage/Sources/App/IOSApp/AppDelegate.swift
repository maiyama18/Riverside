import BackgroundTasks
import BackgroundRefreshUseCase
import CloudSyncState
import Dependencies
import Entities
import LocalPushNotificationClient
import UIKit

@MainActor
final class AppDelegate: UIResponder, UIApplicationDelegate {
    let cloudSyncState = CloudSyncState()
    let persistentProvider = PersistentProvider.cloud
    
    @Dependency(\.localPushNotificationClient) private var localPushNotificationClient
    @Dependency(\.backgroundRefreshUseCase) private var backgroundRefreshUseCase

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        localPushNotificationClient.requestPermission(self)
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundRefreshUseCase.taskIdentifier,
            using: nil
        ) { task in
            Task.detached {
                await self.backgroundRefreshUseCase.execute(
                    task as! BGProcessingTask,
                    self.persistentProvider.backgroundContext,
                    self.cloudSyncState.eventDebouncedPublisher
                )
            }
        }
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound, .badge]
    }
}
