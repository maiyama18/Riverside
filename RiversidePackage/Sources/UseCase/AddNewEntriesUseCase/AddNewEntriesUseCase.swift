import Dependencies
import FeedClient
import Foundation
import Logging
import Utilities
@preconcurrency import Entities
@preconcurrency import CoreData
import SwiftUI

public struct AddNewEntriesUseCase: Sendable {
    public var execute: @Sendable @MainActor (_ context: NSManagedObjectContext, _ feed: FeedModel) async throws -> [EntryInformation]
    public var executeForAllFeeds: @Sendable @MainActor (_ context: NSManagedObjectContext, _ force: Bool) async throws -> [EntryInformation]
}

extension AddNewEntriesUseCase {
    enum FetchResult {
        case success([EntryInformation])
        case timeout
        case error(any Error)
    }
    
    static var live: AddNewEntriesUseCase {
        @Dependency(\.feedClient) var feedClient
        @Dependency(\.logger[.feedModel]) var logger
        
        @Sendable
        @MainActor
        func addNewEntries(context: NSManagedObjectContext, feed: FeedModel) async throws -> [EntryInformation] {
            logger.debug("fetching entries for '\(feed.title ?? "", privacy: .public)'")
            guard let feedURL = feed.url else {
                throw NSError(domain: "FeedUseCase", code: -1)
            }
            let fetchedFeed = try await feedClient.fetch(feedURL)
            let fetchedEntries = fetchedFeed.entries
            
            let existingEntries = feed.entries as? Set<EntryModel> ?? []
            let existingEntryURLs = existingEntries.compactMap(\.url)
            
            let latestEntryPublishedAt = existingEntries.compactMap(\.publishedAt).max() ?? Date(timeIntervalSince1970: 0)
            
            let newEntries = fetchedEntries.filter { $0.publishedAt > latestEntryPublishedAt }
            let addedEntries = newEntries.filter { newEntry in !existingEntryURLs.contains(where: { $0.isSame(as: newEntry.url) }) }
            for entry in addedEntries {
                feed.addToEntries(entry.toModel(context: context))
            }
            logger.debug("fetched entries for '\(feed.title ?? "", privacy: .public)': all \(fetchedEntries.count) entries, new \(newEntries.count), added: \(addedEntries.count)")
            return addedEntries.map {
                EntryInformation(
                    title: $0.title,
                    feedTitle: fetchedFeed.title,
                    publishedAt: $0.publishedAt
                )
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
                    return []
                }
                
                logger.notice("starting add new entries")
                let feeds = try context.fetch(FeedModel.all)
                let result = await withTaskGroup(
                    of: FetchResult.self,
                    returning: ([EntryInformation], Int, Int, Int).self
                ) { group in
                    for feed in feeds {
                        group.addTask {
                            do {
                                let entries = try await withTimeout(for: .seconds(10)) {
                                    try await addNewEntries(context: context, feed: feed)
                                }
                                if let entries {
                                    return .success(entries)
                                } else {
                                    logger.debug("timeout to fetch new entries for '\(feed.title ?? "", privacy: .public)'")
                                    return .timeout
                                }
                            } catch {
                                logger.debug("failed to fetch new entries for '\(feed.title ?? "")': \(error, privacy: .public)")
                                return .error(error)
                            }
                        }
                    }
                    
                    var allEntries: [EntryInformation] = []
                    var successCount = 0
                    var timeoutCount = 0
                    var errorCount = 0
                    for await result in group {
                        switch result {
                        case .success(let entries):
                            allEntries.append(contentsOf: entries)
                            successCount += 1
                        case .timeout:
                            timeoutCount += 1
                        case .error:
                            errorCount += 1
                        }
                    }
                    try? context.saveWithRollback()
                    setLastAddExecutionDate(date: .now)
                    return (allEntries, successCount, timeoutCount, errorCount)
                }
                logger.notice("finished executeForAllFeeds: success \(result.1), timeout \(result.2), error \(result.3)")
                return result.0
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
