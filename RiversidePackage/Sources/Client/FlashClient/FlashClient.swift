import Dependencies
import Drops

public struct FlashClient: Sendable {
    public enum FlashType: Sendable {
        case info
        case error
    }
    
    public var present: @Sendable (_ type: FlashType, _ message: String) -> Void
}

#if canImport(UIKit)
import UIKit

extension FlashClient {
    static let live: FlashClient = .init(
        present: { type, message in
            Drops.hideAll()
            
            let iconSystemName: String = switch type {
            case .info:
                "checkmark.circle"
            case .error:
                "exclamationmark.circle"
            }
            
            let iconColor: UIColor = switch type {
            case .info:
                .systemTeal
            case .error:
                .systemRed
            }

            let drop = Drop(
                title: message,
                titleNumberOfLines: 2,
                icon: UIImage(systemName: iconSystemName)?
                    .withTintColor(iconColor, renderingMode: .alwaysOriginal)
            )
            Drops.show(drop)
        }
    )
}
#else
extension FlashClient {
    static let live: FlashClient = .init(
        present: { type, message in
            // TODO: implement for mac
            print(type, message)
        }
    )
}
#endif

public extension DependencyValues {
    var flashClient: FlashClient {
        get { self[FlashClientKey.self] }
        set { self[FlashClientKey.self] = newValue }
    }
}

private enum FlashClientKey: DependencyKey {
    static let liveValue: FlashClient = .live
}
