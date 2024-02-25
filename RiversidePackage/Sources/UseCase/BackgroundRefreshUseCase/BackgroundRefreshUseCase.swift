import AddNewEntriesUseCase
import BackgroundTasks
@preconcurrency import CoreData
import Combine
import Dependencies
import Entities
import LocalPushNotificationClient
import Logging
import Utilities

public struct BackgroundRefreshUseCase: Sendable {
    public var taskIdentifier: String
    public var schedule: @Sendable () -> Void
    public var execute: @Sendable (
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
            let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
            request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
            
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
            execute: { context, iCloudEventDebouncedPublisher in
                schedule()
                
                let history = BackgroundRefreshHistoryModel(context: context)
                history.startedAt = .now
                do {
                    try context.saveWithRollback()
                    logger.notice("saved background refresh history")
                } catch {
                    logger.error("failed to save refresh history: \(error, privacy: .public)")
                }
                
                await iCloudEventDebouncedPublisher.nextValue()
                
                do {
                    let addedEntries = try await addNewEntriesUseCase.executeForAllFeeds(context, true)
                    if addedEntries.count > 0 {
                        let visibleEntryCount = 3
                        var addedEntryStrings = addedEntries.prefix(visibleEntryCount).map {
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
                    logger.notice("complete background refresh: \(addedEntries.count) entries added")
                } catch {
                    logger.error("failed to background refresh: \(error, privacy: .public)")
                }
            }
        )
    }
}

extension BackgroundRefreshUseCase: DependencyKey {
    public static let liveValue: BackgroundRefreshUseCase = .live(taskIdentifier: "com.muijp.RiversideIOSApp.refreshTask")
}

extension DependencyValues {
    public var backgroundRefreshUseCase: BackgroundRefreshUseCase {
        get { self[BackgroundRefreshUseCase.self] }
        set { self[BackgroundRefreshUseCase.self] = newValue }
    }
}
