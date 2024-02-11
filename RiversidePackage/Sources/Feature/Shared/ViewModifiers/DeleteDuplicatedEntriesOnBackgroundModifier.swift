@preconcurrency import CoreData
import CloudSyncState
import Dependencies
import DeleteDuplicatedEntriesUseCase
import SwiftUI
import Utilities

public extension View {
    func deleteDuplicatedEntriesOnBackground() -> some View {
        modifier(DeleteDuplicatedEntriesOnBackgroundModifier())
    }
}

struct DeleteDuplicatedEntriesOnBackgroundModifier: ViewModifier {
    @Dependency(\.deleteDuplicatedEntriesUseCase) private var deleteDuplicatedEntriesUseCase
    
    @Environment(CloudSyncState.self) private var cloudSyncState
    @Environment(\.managedObjectContext) private var context
    @Environment(\.loadingAllFeedsOnForeground) private var loadingAllFeedsOnForeground
    
    func body(content: Content) -> some View {
        content
            .onBackground { [deleteDuplicatedEntriesUseCase, cloudSyncState, loadingAllFeedsOnForeground, context] in
                guard await !cloudSyncState.syncing,
                      !loadingAllFeedsOnForeground else { return }
                do {
                    try deleteDuplicatedEntriesUseCase.execute(context)
                } catch {}
            }
    }
}
