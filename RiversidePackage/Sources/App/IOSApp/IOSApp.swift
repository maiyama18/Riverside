import NavigationState
import SwiftUI

@MainActor
public struct IOSApp: App {
    private let navigationState = NavigationState()

    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            MainTabScreen()
        }
        .environment(navigationState)
    }
}
