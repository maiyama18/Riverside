import Dependencies
import FeedClient
import Payloads
import Foundation
import Utilities
import Entities
import CoreData
import SwiftUI

public struct SubscribeFeedUseCase: Sendable {
    public enum SubscribeInput {
        case url(URL)
        case feed(Feed)
    }
    
    public var execute: @Sendable @MainActor (_ context: NSManagedObjectContext, _ input: SubscribeInput) async throws -> Feed
}

extension SubscribeFeedUseCase {
    static var live: SubscribeFeedUseCase {
        .init(
            execute: { @MainActor context, input in
                @Dependency(\.feedClient) var feedClient
                
                let feed = switch input {
                case .feed(let feed):
                    feed
                case .url(let url):
                    try await feedClient.fetch(url)
                }
                
                let existingFeedURLs = try context.fetch(FeedModel.all).compactMap(\.url)
                guard existingFeedURLs.filter({ url in url.isSame(as: feed.url) }).isEmpty else {
                    throw NSError(domain: "FeedUseCase", code: -2, userInfo: [
                        NSLocalizedDescriptionKey: "'\(feed.title)' is already subscribed"
                    ])
                }
             
                let (feedModel, entryModels) = feed.toModel(context: context)
                for (i, entryModel) in entryModels.enumerated() {
                    entryModel.read = i >= 3
                    feedModel.addToEntries(entryModel)
                }
                context.insert(feedModel)
                
                try context.saveWithRollback()
                return feed
            }
        )
    }
}

extension SubscribeFeedUseCase: DependencyKey {
    public static let liveValue: SubscribeFeedUseCase = .live
}

public extension DependencyValues {
    var subscribeFeedUseCase: SubscribeFeedUseCase {
        get { self[SubscribeFeedUseCase.self] }
        set { self[SubscribeFeedUseCase.self] = newValue }
    }
}
