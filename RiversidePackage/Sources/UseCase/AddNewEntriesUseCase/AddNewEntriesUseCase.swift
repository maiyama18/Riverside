import Dependencies
import FeedClient
import Foundation
import Logging
import Utilities
@preconcurrency import Entities
@preconcurrency import CoreData
import SwiftUI

public struct AddNewEntriesUseCase: Sendable {
    public var execute: @Sendable @MainActor (_ context: NSManagedObjectContext, _ feed: FeedModel) async throws -> Void
    public var executeForAllFeeds: @Sendable @MainActor (_ context: NSManagedObjectContext, _ force: Bool) async throws -> Void
}

extension AddNewEntriesUseCase {
    static var live: AddNewEntriesUseCase {
        @Dependency(\.feedClient) var feedClient
        @Dependency(\.logger[.feedModel]) var logger
        
        @Sendable
        @MainActor
        func addNewEntries(context: NSManagedObjectContext, feed: FeedModel) async throws {
            guard let feedURL = feed.url else {
                throw NSError(domain: "FeedUseCase", code: -1)
            }
            let fetchedEntries = try await feedClient.fetch(feedURL).entries
            
            let existingEntries = feed.entries as? Set<EntryModel> ?? []
            let existingEntryURLs = existingEntries.compactMap(\.url)
            
            let latestEntryPublishedAt = existingEntries.compactMap(\.publishedAt).max() ?? Date(timeIntervalSince1970: 0)
            
            let newEntries = fetchedEntries.filter { $0.publishedAt > latestEntryPublishedAt }
            let addedEntries = newEntries.filter { newEntry in !existingEntryURLs.contains(where: { $0.isSame(as: newEntry.url) }) }
            for entry in addedEntries {
                feed.addToEntries(entry.toModel(context: context))
            }
            logger.notice("fetched entries for '\(feed.title ?? "", privacy: .public)': all \(fetchedEntries.count) entries, new \(fetchedEntries.count), added: \(addedEntries.count)")
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
            execute: { context, feed in
                try await addNewEntries(context: context, feed: feed)
            },
            executeForAllFeeds: { context, force in
                if force {
                    deleteLastAddExecutionDate()
                }
                
                if let lastExecutionDate = getLastAddExecutionDate(),
                   // 10 min
                   Date.now.timeIntervalSince(lastExecutionDate) < 60 * 10 {
                    logger.notice("skipping add new entries. last execution date: \(lastExecutionDate)")
                    return
                }
                
                logger.notice("starting add new entries")
                let feeds = try context.fetch(FeedModel.all)
                await withThrowingTaskGroup(of: Void.self) { group in
                    for feed in feeds {
                        group.addTask {
                            try await addNewEntries(context: context, feed: feed)
                        }
                    }
                    do {
                        try await group.waitForAll()
                        try context.saveWithRollback()
                        setLastAddExecutionDate(date: .now)
                    } catch {
                        logger.notice("failed to save new entries: \(error, privacy: .public)")
                    }
                }
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
