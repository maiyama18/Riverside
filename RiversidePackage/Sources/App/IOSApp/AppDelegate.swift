import Dependencies
import LocalPushNotificationClient
import UIKit

final class AppDelegate: UIResponder, UIApplicationDelegate {
    @Dependency(\.localPushNotificationClient) private var localPushNotificationClient
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        localPushNotificationClient.requestPermission(self)
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound, .badge]
    }
}
