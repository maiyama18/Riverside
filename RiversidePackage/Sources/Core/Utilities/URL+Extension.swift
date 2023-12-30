import UIKit

public extension URL {
    var isValid: Bool {
        UIApplication.shared.canOpenURL(self)
    }
}
