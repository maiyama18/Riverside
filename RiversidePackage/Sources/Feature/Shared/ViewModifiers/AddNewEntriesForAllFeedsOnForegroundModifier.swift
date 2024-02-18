import AddNewEntriesUseCase
import CloudSyncState
import Dependencies
import Logging
import SwiftUI

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
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var addNewEntriesExecutedSinceLastBecomeForeground: Bool = false
    
    func body(content: Content) -> some View {
        content
            .onForeground { @MainActor in
                addNewEntriesExecutedSinceLastBecomeForeground = false
            }
            .task(id: cloudSyncState.syncing) {
                guard scenePhase == .active,
                      !cloudSyncState.syncing,
                      !addNewEntriesExecutedSinceLastBecomeForeground else { return }
                
                loading = true
                defer { loading = false }
                
                do {
                    try await Task.sleep(for: .seconds(1.5))
                    logger.notice("addNewEntriesForAllFeeds started")
                    _ = try await addNewEntriesUseCase.executeForAllFeeds(context, false)
                    addNewEntriesExecutedSinceLastBecomeForeground = true
                    logger.notice("addNewEntriesForAllFeeds finished")
                } catch {
                    if Task.isCancelled {
                        logger.notice("addNewEntriesForAllFeeds task cancelled")
                    } else {
                        logger.error("addNewEntriesForAllFeeds failed: \(error)")
                    }
                }
            }
    }
}
