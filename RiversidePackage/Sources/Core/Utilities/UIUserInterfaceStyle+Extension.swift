#if os(iOS)
import UIKit

public extension UIUserInterfaceStyle {
    static var all: [UIUserInterfaceStyle] {
        [.unspecified, .light, .dark]
    }
    
    var string: String {
        switch self {
        case .unspecified:
            "System"
        case .light:
            "Light"
        case .dark:
            "Dark"
        @unknown default:
            "Unknown"
        }
    }
}
#endif
