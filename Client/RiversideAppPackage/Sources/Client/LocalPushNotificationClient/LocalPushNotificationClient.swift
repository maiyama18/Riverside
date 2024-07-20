import Dependencies
import Foundation
import Logging
import UserNotifications

public struct LocalPushNotificationClient : Sendable {
    public var getPermission: @Sendable () async -> UNAuthorizationStatus
    public var requestPermission: @Sendable (_ delegate: any UNUserNotificationCenterDelegate) -> Void
    public var send: @Sendable (_ title: String, _ body: String?) -> Void
}

extension LocalPushNotificationClient {
    public static func live(userDefaults: UserDefaults) -> LocalPushNotificationClient {
        @Dependency(\.logger[.app]) var logger
        
        return .init(
            getPermission: {
                let center = UNUserNotificationCenter.current()
                return await withCheckedContinuation { continuation in
                    center.getNotificationSettings { continuation.resume(returning: $0.authorizationStatus) }
                }
            },
            requestPermission: { delegate in
                let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        logger.error("failed in requesting permission for local push notifications: \(error, privacy: .public)")
                    } else {
                        if granted {
                            logger.notice("push notification permission granted")
                        } else {
                            logger.notice("push notification permission not granted")
                        }
                    }
                }
                center.delegate = delegate
            },
            send: { title, body in
                guard userDefaults.bool(forKey: "background-refresh-push-notification-enabled") else {
                    return
                }
                
                let content = UNMutableNotificationContent()
                content.title = title
                if let body {
                    content.body = body
                }
                content.sound = UNNotificationSound.default

                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        logger.error("failed to schedule local push notification: \(error, privacy: .public)")
                    } else {
                        logger.notice("scheduled local push notification \(title, privacy: .public) \(body ?? "", privacy: .public)")
                    }
                }
            }
        )
    }
}

extension LocalPushNotificationClient: DependencyKey {
    public static let liveValue: LocalPushNotificationClient = .live(userDefaults: .standard)
}
    
extension DependencyValues {
    public var localPushNotificationClient: LocalPushNotificationClient {
        get { self[LocalPushNotificationClient.self] }
        set { self[LocalPushNotificationClient.self] = newValue }
    }
}
