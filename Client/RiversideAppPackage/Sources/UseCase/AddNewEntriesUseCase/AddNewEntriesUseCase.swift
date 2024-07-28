import Dependencies
import FeedClient
import Foundation
import RiversideLogging
import Payloads
import Utilities
@preconcurrency import Entities
@preconcurrency import CoreData
import SwiftUI
import WidgetKit

public struct AddNewEntriesUseCase: Sendable {
    public var execute: @Sendable @MainActor (_ context: NSManagedObjectContext, _ feed: FeedModel) async throws -> [EntryInformation]
    public var executeInBackground: @Sendable (_ backgroundContext: NSManagedObjectContext, _ feed: FeedModel) async throws -> [EntryInformation]
}

extension AddNewEntriesUseCase {
    static var live: AddNewEntriesUseCase {
        @Dependency(\.feedClient) var feedClient
        @Dependency(\.logger[.feedModel]) var logger
        
        @Sendable
        func addNewEntries(context: NSManagedObjectContext, existingFeed: FeedModel, fetchedFeed: Feed) -> [EntryInformation]  {
            let fetchedEntries = fetchedFeed.entries
            
            let existingEntries = existingFeed.entries as? Set<EntryModel> ?? []
            let existingEntryURLs = existingEntries.compactMap(\.url)
            
            let latestEntryPublishedAt = existingEntries.compactMap(\.publishedAt).max() ?? Date(timeIntervalSince1970: 0)
            
            let newEntries = fetchedEntries.filter { $0.publishedAt > latestEntryPublishedAt }
            let addedEntries = newEntries.filter { newEntry in !existingEntryURLs.contains(where: { $0.isSame(as: newEntry.url) }) }
            for entry in addedEntries {
                existingFeed.addToEntries(entry.toModel(context: context))
            }
            logger.debug("fetched entries for '\(fetchedFeed.title, privacy: .public)': all \(fetchedEntries.count) entries, new \(newEntries.count), added: \(addedEntries.count)")
            return addedEntries.map {
                EntryInformation(
                    title: $0.title,
                    feedTitle: fetchedFeed.title,
                    publishedAt: $0.publishedAt
                )
            }
        }
        
        @Sendable
        func fetchFeed(feed: FeedModel) async throws -> Feed {
            logger.debug("fetching entries for '\(feed.title ?? "", privacy: .public)'")
            guard let feedURL = feed.url else {
                throw NSError(domain: "FeedUseCase", code: -1)
            }
            return try await feedClient.fetch(feedURL)
        }
        
        return .init(
            execute: { @MainActor context, feed in
                let fetchedFeed = try await fetchFeed(feed: feed)
                return addNewEntries(
                    context: context,
                    existingFeed: feed,
                    fetchedFeed: fetchedFeed
                )
            },
            executeInBackground: { @DatabaseActor context, feed in
                let fetchedFeed = try await fetchFeed(feed: feed)
                return addNewEntries(
                    context: context,
                    existingFeed: feed,
                    fetchedFeed: fetchedFeed
                )
            }
        )
    }
}

extension AddNewEntriesUseCase: DependencyKey {
    public static let liveValue: AddNewEntriesUseCase = .live
}

public extension DependencyValues {
    var addNewEntriesUseCase: AddNewEntriesUseCase {
        get { self[AddNewEntriesUseCase.self] }
        set { self[AddNewEntriesUseCase.self] = newValue }
    }
}

@globalActor actor DatabaseActor: GlobalActor {
    static let shared = DatabaseActor()
}
