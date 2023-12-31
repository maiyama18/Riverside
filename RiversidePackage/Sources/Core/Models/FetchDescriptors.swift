import Foundation
import SwiftData

public extension FeedModel {
    static var all: FetchDescriptor<FeedModel> {
        FetchDescriptor(sortBy: [SortDescriptor(\FeedModel.title, order: .forward)])
    }
}

public extension EntryModel {
    static func all(for feed: FeedModel) -> FetchDescriptor<EntryModel> {
        let feedURL = feed.url
        return FetchDescriptor(
            predicate: #Predicate { $0.feed?.url == feedURL },
            sortBy: [SortDescriptor(\.publishedAt, order: .reverse)]
        )
    }
}
