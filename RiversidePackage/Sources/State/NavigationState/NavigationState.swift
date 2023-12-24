import Observation
import SwiftUI

@Observable
@MainActor
public final class NavigationState {
    public init() {}
    
    private var _mainTab: MainTab = .stream
    public var mainTab: Binding<MainTab> {
        .init(get: { self._mainTab }, set: { self._mainTab = $0 })
    }
}
