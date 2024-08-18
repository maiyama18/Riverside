import BackgroundTasks
@preconcurrency import CoreData
import Combine
import Dependencies
import Entities
import FeedClient
import LocalPushNotificationClient
import RiversideLogging
import Utilities
import Payloads
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
        @Dependency(\.feedClient) var feedClient
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

                try? await withTimeout(for: .seconds(10)) {
                    try? await iCloudEventDebouncedPublisher.nextValue()
                }
                
                var addedEntries: [(entry: Entry, feedTitle: String)] = []
                do {
                    let existingFeeds = try context.fetch(FeedModel.all).uniqued(on: { $0.url }).shuffled()
                    let fetchedFeeds = try await feedClient.fetchFeeds(existingFeeds.compactMap(\.url), false)
                    for fetchedFeed in fetchedFeeds {
                        guard let existingFeed = existingFeeds.first(where: { $0.url == fetchedFeed.url }) else { continue }
                        let newEntries = existingFeed.addNewEntries(fetchedFeed.entries)
                        for newEntry in newEntries {
                            addedEntries.append((newEntry, feedTitle: fetchedFeed.title))
                        }
                    }
                } catch {
                    history.errorMessage = error.localizedDescription
                    logger.error("failed to execute background refresh: \(error, privacy: .public)")
                }
                history.addedEntryTitles = addedEntries.map(\.entry.title)
                history.finishedAt = .now
                do {
                    try context.saveWithRollback()
                    logger.notice("saved background refresh history")
                } catch {
                    logger.error("failed to save refresh history: \(error, privacy: .public)")
                }
                if addedEntries.count > 0 {
                    // send push notification
                    let visibleEntryCount = 3
                    var addedEntryStrings = addedEntries.sorted(by: { $0.entry.publishedAt > $1.entry.publishedAt }).prefix(visibleEntryCount).map {
                        let title = $0.entry.title.count > 20 ? $0.entry.title.prefix(20) + "..." : $0.entry.title
                        return "\(title) | \($0.feedTitle)"
                    }
                    if addedEntries.count > visibleEntryCount {
                        addedEntryStrings.append("and more!")
                    }
                    
                    localPushNotificationClient.send(
                        "\(addedEntries.count) new entries published",
                        addedEntryStrings.joined(separator: "\n")
                    )
                    
                    // reload widget
                    WidgetCenter.shared.reloadAllTimelines()
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
