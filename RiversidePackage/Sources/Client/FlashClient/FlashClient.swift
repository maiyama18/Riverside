import Dependencies
import SystemNotification
import SwiftUI

public enum FlashType: Sendable {
    case info
    case error
}

@MainActor
public protocol FlashClient: Sendable {
    func injectContext(_ context: SystemNotificationContext)
    func present(type: FlashType, message: String)
}

@MainActor
final class FlashClientLive: FlashClient {
    private var context: SystemNotificationContext?
    
    nonisolated init() {}
    
    func injectContext(_ context: SystemNotificationContext) {
        self.context = context
    }
    
    func present(type: FlashType, message: String) {
        let icon: some View = switch type {
        case .info:
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.teal)
        case .error:
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(.red)
        }
        context?.present {
            SystemNotificationMessage(
                icon: icon,
                text: message,
                style: .init(textColor: .primary)
            )
        }
    }
}

public extension DependencyValues {
    var flashClient: any FlashClient {
        get { self[FlashClientKey.self] }
        set { self[FlashClientKey.self] = newValue }
    }
}

private enum FlashClientKey: DependencyKey {
    static let liveValue: any FlashClient = FlashClientLive()
}
