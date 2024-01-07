#if canImport(UIKit)
import UIKit
import SafariServices

@MainActor
public func showSafari(url: URL) {
    let safari = SFSafariViewController(url: url)
    UIApplication.shared.firstKeyWindow?.rootViewController?.present(safari, animated: true)
}

extension UIApplication {
    var firstKeyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .first?.keyWindow
    }
}
#endif
