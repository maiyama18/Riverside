import UIKit
import SafariServices

@MainActor
public func showSafari(url: URL, onDisappear: @escaping () -> Void = {}) {
    let safari = SafariViewController(url: url, onDisappear: onDisappear)
    UIApplication.shared.firstKeyWindow?.rootViewController?.present(safari, animated: true)
}

@MainActor
public func dismissSafari() {
    guard let rootViewController = UIApplication.shared.firstKeyWindow?.rootViewController,
          let safariViewController = rootViewController.presentedViewController as? SafariViewController else {
        return
    }
    safariViewController.dismiss(animated: true)
}

final class SafariViewController: SFSafariViewController {
    private let onDisappear: () -> Void
    
    init(url: URL, onDisappear: @escaping () -> Void) {
        self.onDisappear = onDisappear
        super.init(url: url, configuration: .init())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDisappear()
    }
}

extension UIApplication {
    var firstKeyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .first?.keyWindow
    }
}
