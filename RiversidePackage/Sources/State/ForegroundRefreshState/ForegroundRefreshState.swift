import AddNewEntriesUseCase
@preconcurrency import CoreData
import Dependencies
import Entities
import Foundation
import Logging
import Observation
import Utilities
import WidgetKit

@Observable
@MainActor
public final class ForegroundRefreshState {
    enum FetchResult {
        case success([EntryInformation])
        case timeout
        case error(any Error)
    }
    
    public enum State {
        case idle
        case refreshing(progress: Double)
        
        public var isRefreshing: Bool {
            if case .refreshing = self {
                true
            } else {
                false
            }
        }
    }
    
    @ObservationIgnored
    @Dependency(\.addNewEntriesUseCase) private var addNewEntriesUseCase
    
    @ObservationIgnored
    @Dependency(\.logger[.foregroundRefresh]) private var logger

    public var state: State = .idle
    
    private var userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public func refresh(context: NSManagedObjectContext, force: Bool, timeout: Duration, retryCount: Int = 1) async {
        let startedAt: Date = .now
        
        guard !state.isRefreshing else { return }
        state = .refreshing(progress: 0)
        defer { state = .idle }
        
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
        guard let feeds = try? context.fetch(FeedModel.all).uniqued(on: { $0.url }).shuffled() else {
            return
        }
        let result = await withTaskGroup(
            of: FetchResult.self,
            returning: ([EntryInformation], Int, Int, Int).self
        ) { group in
            let batchSize = 8
            @Sendable func addNewEntries(feed: FeedModel) async -> FetchResult {
                do {
                    let entries = try await withRetry(count: retryCount) {
                        try await withTimeout(for: timeout) {
                            try await self.addNewEntriesUseCase.execute(context, feed)
                        }
                    }
                    return .success(entries)
                } catch {
                    if error is TimeoutError {
                        await self.logger.debug("timeout to fetch new entries for '\(feed.title ?? "", privacy: .public)'")
                        return .timeout
                    } else {
                        await self.logger.debug("failed to fetch new entries for '\(feed.title ?? "")': \(error, privacy: .public)")
                        return .error(error)
                    }
                }
            }
            
            for i in 0..<batchSize {
                group.addTask {
                    await addNewEntries(feed: feeds[i])
                }
            }
            var index = batchSize
            
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
                self.state = .refreshing(progress: Double(successCount + timeoutCount + errorCount) / Double(feeds.count))
                
                if index < feeds.count {
                    let feed = feeds[index]
                    group.addTask {
                        await addNewEntries(feed: feed)
                    }
                    index += 1
                }
            }
            self.state = .idle
            try? context.saveWithRollback()
            WidgetCenter.shared.reloadAllTimelines()
            setLastAddExecutionDate(date: .now)
            return (allEntries, successCount, timeoutCount, errorCount)
        }
        logger.notice("finished foreground refresh (\(Date.now.timeIntervalSince(startedAt)) s): success \(result.1), timeout \(result.2), error \(result.3)")
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
