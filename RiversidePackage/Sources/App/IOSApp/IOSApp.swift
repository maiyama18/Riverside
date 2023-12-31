import Models
import NavigationState
import SwiftData
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
        .modelContainer(for: FeedModel.self)
    }
}
