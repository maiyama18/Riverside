import Models
import RootFeature
import SwiftData
import SwiftUI

public struct MacApp: App {
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            RootScreen()
                .modelContainer(for: FeedModel.self)
        }
    }
}
