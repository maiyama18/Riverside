import AddNewEntriesUseCase
import CloudSyncState
import Dependencies
import Entities
import Logging
import SwiftUI
import Utilities

extension View {
    /// iCloud 同期が落ち着いたタイミングで、すべてのフィードを更新する。
    /// Foreground になって以降１回のみ実行する。
    public func addNewEntriesForAllFeedsOnForeground(loading: Binding<Bool>) -> some View {
        modifier(AddNewEntriesForAllFeedsOnForegroundModifier(loading: loading))
    }
}

struct AddNewEntriesForAllFeedsOnForegroundModifier: ViewModifier {
    @Binding var loading: Bool
    
    @Dependency(\.addNewEntriesUseCase) private var addNewEntriesUseCase
    @Dependency(\.logger[.feature]) private var logger
    
    @Environment(CloudSyncState.self) private var cloudSyncState
    @Environment(\.managedObjectContext) private var context
    
    func body(content: Content) -> some View {
        content
            .onForeground { @MainActor in
                loading = true
                defer { loading = false }
                
                let history = BackgroundRefreshHistoryModel(context: context)
                history.startedAt = .now
                do {
                    try context.saveWithRollback()
                    logger.notice("saved foreground refresh history")
                } catch {
                    logger.error("failed to save refresh history: \(error, privacy: .public)")
                }
                
                await withTimeout(for: .seconds(5)) { [eventDebouncedPublisher = cloudSyncState.eventDebouncedPublisher] in
                    await eventDebouncedPublisher.nextValue()
                }
                
                do {
                    let addedEntries = try await addNewEntriesUseCase.executeForAllFeeds(context, true)
                    logger.notice("complete foreground refresh: \(addedEntries.count) entries added")
                } catch {
                    logger.error("failed to foreground refresh: \(error, privacy: .public)")
                }
            }
    }
}
