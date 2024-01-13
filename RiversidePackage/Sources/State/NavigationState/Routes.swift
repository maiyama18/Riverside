import Models
import SwiftData

public enum FeedsRoute: Hashable {
    case feedDetail(feed: FeedModel)
}

public enum SettingsRoute: Hashable {
    case cloudSyncStatus
}
