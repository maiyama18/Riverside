#if os(iOS)
import Dependencies
import UIKit

public struct AppAppearanceClient: Sendable {
    public var apply: @Sendable @MainActor (UIUserInterfaceStyle) -> Void
}

extension AppAppearanceClient {
    public static let live: AppAppearanceClient = AppAppearanceClient(
        apply: { appearance in
            guard let window = UIApplication.shared.firstWindow else {
                return
            }
            window.overrideUserInterfaceStyle = appearance
        }
    )
}

extension UIApplication {
    var firstWindow: UIWindow? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window
    }
}

extension AppAppearanceClient: DependencyKey {
    public static let liveValue: AppAppearanceClient = .live
}

extension DependencyValues {
    public var appAppearanceClient: AppAppearanceClient {
        get { self[AppAppearanceClient.self] }
        set { self[AppAppearanceClient.self] = newValue }
    }
}
#endif
