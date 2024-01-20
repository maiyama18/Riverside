import Dependencies
import FeedClient
import Foundation
import Utilities
@preconcurrency import Entities
@preconcurrency import CoreData
import SwiftUI

public struct FeedUseCase: Sendable {
    public enum SubscribeInput {
        case url(URL)
        case feed(Feed)
    }
    
    public var addNewEpisodes: @Sendable @MainActor (_ context: NSManagedObjectContext, _ feed: FeedModel) async throws -> Void
    public var addNewEpisodesForAllFeeds: @Sendable @MainActor (_ context: NSManagedObjectContext, _ force: Bool) async throws -> Void
    public var subscribeFeed: @Sendable @MainActor (_ context: NSManagedObjectContext, _ input: SubscribeInput) async throws -> Feed
}

extension FeedUseCase {
    static var live: FeedUseCase {
        @Dependency(\.feedClient) var feedClient
        
        @Sendable
        @MainActor
        func addNewEpisodes(context: NSManagedObjectContext, feed: FeedModel) async throws {
            guard let feedURL = feed.url else {
                throw NSError(domain: "FeedUseCase", code: -1)
            }
            let fetchedEntries = try await feedClient.fetch(feedURL).entries
            
            let existingEntries = feed.entries as? Set<EntryModel> ?? []
            let existingEntryURLs = existingEntries.compactMap(\.url)
            
            let latestEntryPublishedAt = existingEntries.compactMap(\.publishedAt).max() ?? Date(timeIntervalSince1970: 0)
            
            let newEntries = fetchedEntries.filter { $0.publishedAt > latestEntryPublishedAt }
            
            for newEntry in newEntries {
                if !existingEntryURLs.compactMap({ $0 }).contains(where: { $0.isSame(as: newEntry.url) }) {
                    feed.addToEntries(newEntry.toModel(context: context))
                }
            }
        }
        
        @Sendable
        func getLastAddExecutionDate() -> Date? {
            UserDefaults.standard.object(forKey: "last-all-episodes-fetched-at") as? Date
        }
        
        @Sendable
        func deleteLastAddExecutionDate() {
            UserDefaults.standard.removeObject(forKey: "last-all-episodes-fetched-at")
        }
        
        @Sendable
        func setLastAddExecutionDate(date: Date) {
            UserDefaults.standard.setValue(date, forKey: "last-all-episodes-fetched-at")
        }
        
        return .init(
            addNewEpisodes: { context, feed in
                try await addNewEpisodes(context: context, feed: feed)
            },
            addNewEpisodesForAllFeeds: { context, force in
                if force {
                    deleteLastAddExecutionDate()
                }
                
                if let lastExecutionDate = getLastAddExecutionDate(),
                   // 10 min
                   Date.now.timeIntervalSince(lastExecutionDate) < 60 * 10 {
                    return
                }
                
                let feeds = try context.fetch(FeedModel.all)
                await withThrowingTaskGroup(of: Void.self) { group in
                    for feed in feeds {
                        group.addTask {
                            try await addNewEpisodes(context: context, feed: feed)
                        }
                    }
                    do {
                        try await group.waitForAll()
                        setLastAddExecutionDate(date: .now)
                    } catch {
                        print(error)
                    }
                }
            },
            subscribeFeed: { context, input in
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

public extension DependencyValues {
    var feedUseCase: FeedUseCase {
        get { self[FeedUseCaseKey.self] }
        set { self[FeedUseCaseKey.self] = newValue }
    }
}

private enum FeedUseCaseKey: DependencyKey {
    static let liveValue: FeedUseCase = .live
}
