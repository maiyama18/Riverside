@preconcurrency import CoreData
import CloudSyncState
import Dependencies
import DeleteDuplicatedEntriesUseCase
import ForegroundRefreshState
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
    @Environment(ForegroundRefreshState.self) private var foregroundRefreshState
    @Environment(\.managedObjectContext) private var context
    
    func body(content: Content) -> some View {
        content
            .onBackground { [context, deleteDuplicatedEntriesUseCase, refreshing = cloudSyncState.syncing || foregroundRefreshState.state.isRefreshing] in
                guard !refreshing else { return }
                do {
                    try deleteDuplicatedEntriesUseCase.execute(context)
                } catch {}
            }
    }
}
