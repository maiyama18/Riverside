@preconcurrency import CoreData
import CloudSyncState
import Dependencies
import Entities
import Foundation
import FeedClient
import RiversideLogging
import Observation
import Utilities
import WidgetKit

@Observable
@MainActor
public final class ForegroundRefreshState {
    @ObservationIgnored
    @Dependency(\.feedClient) private var feedClient

    @ObservationIgnored
    @Dependency(\.logger[.foregroundRefresh]) private var logger

    public var isRefreshing: Bool = false
    
    private var userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public func refresh(
        context: NSManagedObjectContext,
        cloudSyncState: CloudSyncState,
        force: Bool,
        timeout: Duration,
        retryCount: Int = 1
    ) async {
        let startedAt: Date = .now
        
        guard !isRefreshing else { return }
        isRefreshing = true
        defer {
            isRefreshing = false
        }
        
        if force {
            deleteLastAddExecutionDate()
        }
        
        if let lastExecutionDate = getLastAddExecutionDate(),
           // 10 min
           Date.now.timeIntervalSince(lastExecutionDate) < 60 * 10 {
            logger.notice("skipping foreground refresh. last execution date: \(lastExecutionDate)")
            return
        }
        
        if !force {
            let history = ForegroundRefreshHistoryModel(context: context)
            history.startedAt = .now
            do {
                try context.saveWithRollback()
                logger.notice("saved background refresh history")
            } catch {
                logger.error("failed to save refresh history: \(error, privacy: .public)")
            }
            
            try? await withTimeout(for: .seconds(10)) {
                try? await cloudSyncState.eventDebouncedPublisher.nextValue()
            }
        }

        guard !cloudSyncState.syncing else {
            logger.notice("skipping foreground refresh. iCloud sync ongoing")
            return
        }
        
        logger.notice("starting add new entries")
        guard let existingFeeds = try? context.fetch(FeedModel.all).uniqued(on: { $0.url }).shuffled() else {
            return
        }
        do {
            let fetchedFeeds = try await feedClient.fetchFeeds(existingFeeds.compactMap(\.url))
            for fetchedFeed in fetchedFeeds {
                guard let existingFeed = existingFeeds.first(where: { $0.url == fetchedFeed.url }) else { continue }
                _ = existingFeed.addNewEntries(fetchedFeed.entries)
            }
        } catch {
            logger.error("failed to fetch feeds: \(error, privacy: .public)")
        }
    }
    
    private func getLastAddExecutionDate() -> Date? {
        userDefaults.object(forKey: "last-all-episodes-fetched-at") as? Date
    }
    
    private func deleteLastAddExecutionDate() {
        userDefaults.removeObject(forKey: "last-all-episodes-fetched-at")
    }
    
    private func setLastAddExecutionDate(date: Date) {
        userDefaults.setValue(date, forKey: "last-all-episodes-fetched-at")
    }
}
