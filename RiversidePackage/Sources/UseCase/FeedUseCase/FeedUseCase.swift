import Dependencies
import FeedClient
import Foundation
import Utilities
@preconcurrency import Models
import SwiftData
import SwiftUI

public struct FeedUseCase: Sendable {
    public var addNewEpisodes: @Sendable (_ feed: FeedModel) async throws -> Void
    public var addNewEpisodesForAllFeeds: @Sendable (_ context: ModelContext) async throws -> Void
}

extension FeedUseCase {
    static var live: FeedUseCase {
        @Dependency(\.feedClient) var feedClient
        
        @Sendable
        func addNewEpisodes(for feed: FeedModel) async throws {
            guard let feedURL = URL(string: feed.url) else {
                throw NSError(domain: "FeedUseCase", code: -1)
            }
            let fetchedEntries = try await feedClient.fetch(feedURL).entries
            
            let existingEntries = feed.entries ?? []
            let existingEntryURLs = existingEntries.map(\.url)
            
            let latestEntryPublishedAt = existingEntries.map(\.publishedAt).max() ?? Date(timeIntervalSince1970: 0)
            
            let newEntries = fetchedEntries.filter { $0.publishedAt > latestEntryPublishedAt }
            
            for newEntry in newEntries {
                if !existingEntryURLs.compactMap(URL.init(string:)).contains(where: { $0.isSame(as: newEntry.url) }) {
                    newEntry.toModel().feed = feed
                }
            }
        }
        
        @Sendable
        func getLastAddExecutionDate() -> Date? {
            UserDefaults.standard.object(forKey: "last-all-episodes-fetched-at") as? Date
        }
        
        @Sendable
        func setLastAddExecutionDate(date: Date) {
            UserDefaults.standard.setValue(date, forKey: "last-all-episodes-fetched-at")
        }
        
        return .init(
            addNewEpisodes: { feed in
                try await addNewEpisodes(for: feed)
            },
            addNewEpisodesForAllFeeds: { context in
                if let lastExecutionDate = getLastAddExecutionDate(),
                   // 10 min
                   Date.now.timeIntervalSince(lastExecutionDate) < 1 * 10 {
                    return
                }
                
                let feeds = try context.fetch(FeedModel.all)
                await withThrowingTaskGroup(of: Void.self) { group in
                    for feed in feeds {
                        group.addTask {
                            try await addNewEpisodes(for: feed)
                        }
                    }
                    do {
                        try await group.waitForAll()
                        setLastAddExecutionDate(date: .now)
                    } catch {
                        print(error)
                    }
                }
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