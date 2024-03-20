import AddNewEntriesUseCase
import BackgroundTasks
@preconcurrency import CoreData
import Combine
import Dependencies
import Entities
import LocalPushNotificationClient
import Logging
import Utilities
import WidgetKit

public struct BackgroundRefreshUseCase: Sendable {
    public var taskIdentifier: String
    public var schedule: @Sendable () -> Void
    public var execute: @Sendable (
        _ task: BGProcessingTask,
        _ context: NSManagedObjectContext,
        _ iCloudEventDebouncedPublisher: any Publisher<Void, Never>
    ) async -> Void
}

extension BackgroundRefreshUseCase {
    public static func live(taskIdentifier: String) -> BackgroundRefreshUseCase {
        @Dependency(\.addNewEntriesUseCase) var addNewEntriesUseCase
        @Dependency(\.localPushNotificationClient) var localPushNotificationClient
        @Dependency(\.logger[.background]) var logger
        
        @Sendable
        func schedule() {
            let request = BGProcessingTaskRequest(identifier: taskIdentifier)
            request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
            request.requiresNetworkConnectivity = true
            
            do {
                try BGTaskScheduler.shared.submit(request)
                logger.notice("scheduled background task")
            } catch {
                logger.error("failed to schedule background task: \(error, privacy: .public)")
            }
        }
        
        @Sendable
        func addNewEntries(context: NSManagedObjectContext, history: BackgroundRefreshHistoryModel) async throws -> [EntryInformation] {
            let feeds = try context.fetch(FeedModel.all).uniqued(on: { $0.url }).shuffled()
            
            history.warningMessages = []
            return await withTaskGroup(of: [EntryInformation].self) { group in
                for feed in feeds {
                    group.addTask {
                        do {
                            let entries = try await withRetry(count: 3) {
                                try await withTimeout(for: .seconds(10)) {
                                    try await addNewEntriesUseCase.execute(context, feed)
                                }
                            }
                            return entries
                        } catch {
                            history.warningMessages?.append("'\(feed.title ?? "")': \(error.localizedDescription)")
                            return []
                        }
                    }
                }
                
                var allEntries: [EntryInformation] = []
                for await entries in group {
                    allEntries.append(contentsOf: entries)
                }
                try? context.saveWithRollback()
                WidgetCenter.shared.reloadAllTimelines()
                return allEntries
            }
        }
        
        return BackgroundRefreshUseCase(
            taskIdentifier: taskIdentifier,
            schedule: schedule,
            execute: { task, context, iCloudEventDebouncedPublisher in
                schedule()
                
                let history = BackgroundRefreshHistoryModel(context: context)
                history.startedAt = .now
                do {
                    try context.saveWithRollback()
                    logger.notice("saved background refresh history")
                } catch {
                    logger.error("failed to save refresh history: \(error, privacy: .public)")
                }
                
                task.expirationHandler = {
                    logger.notice("background refresh expired")
                    
                    history.finishedAt = .now
                    history.errorMessage = "task expired"
                    try? context.saveWithRollback()
                }

                await withTimeout(for: .seconds(10)) {
                    try? await iCloudEventDebouncedPublisher.nextValue()
                }
                
                do {
                    let addedEntries = try await addNewEntries(context: context, history: history)
                    history.addedEntryTitles = addedEntries.map(\.title)
                    if addedEntries.count > 0 {
                        let visibleEntryCount = 3
                        var addedEntryStrings = addedEntries.sorted(by: { $0.publishedAt > $1.publishedAt }).prefix(visibleEntryCount).map {
                            let title = $0.title.count > 20 ? $0.title.prefix(20) + "..." : $0.title
                            return "\(title) | \($0.feedTitle)"
                        }
                        if addedEntries.count > visibleEntryCount {
                            addedEntryStrings.append("and more!")
                        }
                        
                        localPushNotificationClient.send(
                            "\(addedEntries.count) new entries published",
                            addedEntryStrings.joined(separator: "\n")
                        )
                    }
                    logger.notice("complete executeForAllFeeds: \(addedEntries.count) entries added")
                } catch {
                    history.errorMessage = error.localizedDescription
                    logger.error("failed to execute executeForAllFeeds: \(error, privacy: .public)")
                }
            
                history.finishedAt = .now
                do {
                    try context.saveWithRollback()
                    logger.notice("saved background refresh history")
                } catch {
                    logger.error("failed to save refresh history: \(error, privacy: .public)")
                }
                task.setTaskCompleted(success: true)
            }
        )
    }
}

extension BackgroundRefreshUseCase: DependencyKey {
    public static let liveValue: BackgroundRefreshUseCase = .live(taskIdentifier: "com.muijp.RiversideIOSApp.processingTask")
}

extension DependencyValues {
    public var backgroundRefreshUseCase: BackgroundRefreshUseCase {
        get { self[BackgroundRefreshUseCase.self] }
        set { self[BackgroundRefreshUseCase.self] = newValue }
    }
}
