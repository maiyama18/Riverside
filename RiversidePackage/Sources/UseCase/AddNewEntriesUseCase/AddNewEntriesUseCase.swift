import Dependencies
import FeedClient
import Foundation
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
                    return
                }
                
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
                        print(error)
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
