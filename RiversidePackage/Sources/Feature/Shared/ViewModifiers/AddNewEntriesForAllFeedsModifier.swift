import AddNewEntriesUseCase
import CloudSyncState
import Dependencies
import Logging
import SwiftUI

extension View {
    /// iCloud 同期が落ち着いたタイミングで、すべてのフィードを更新する。
    /// Foreground になって以降１回のみ実行する。
    public func addNewEntriesForAllFeeds(loading: Binding<Bool>) -> some View {
        modifier(AddNewEntriesForAllFeedsModifier(loading: loading))
    }
}

struct AddNewEntriesForAllFeedsModifier: ViewModifier {
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
                    try await Task.sleep(for: .seconds(3))
                    logger.notice("addNewEntriesForAllFeeds started")
                    try await addNewEntriesUseCase.executeForAllFeeds(context, false)
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
