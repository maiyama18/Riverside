import SwiftUI

private enum LoadingAllFeedsOnForegroundKey: EnvironmentKey {
    static var defaultValue: Bool = false
}

extension EnvironmentValues {
    public var loadingAllFeedsOnForeground: Bool {
        get { self[LoadingAllFeedsOnForegroundKey.self] }
        set { self[LoadingAllFeedsOnForegroundKey.self] = newValue }
    }
}
