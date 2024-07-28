import Algorithms
@preconcurrency import CoreData
import CloudSyncState
import Dependencies
import Entities
import ForegroundRefreshState
import FlashClient
import SwiftUI
import ViewModifiers
import UIComponents

@MainActor
public struct RootScreen: View {
    @AppStorage("unread-only") private var unreadOnly: Bool = true
    
    @Dependency(\.flashClient) private var flashClient
    
    @Environment(CloudSyncState.self) private var cloudSyncState
    @Environment(ForegroundRefreshState.self) private var foregroundRefreshState
    @Environment(\.managedObjectContext) private var context
    
    @State private var selectedFeedID: ObjectIdentifier? = nil
    @State private var selectedEntryID: ObjectIdentifier? = nil
    
    @FetchRequest(fetchRequest: EntryModel.all) private var entries: FetchedResults<EntryModel>
    
    public init() {}
    
    private var selectedEntry: EntryModel? {
        guard let selectedEntryID else { return nil }
        return entries.first(where: { $0.id == selectedEntryID })
    }    
    
    public var body: some View {
        NavigationSplitView {
            SidebarListView(selectedFeedID: $selectedFeedID)
        } content: {
            EntryListView(
                allEntries: entries.uniqued(on: \.url),
                unreadOnly: unreadOnly,
                selectedFeedID: $selectedFeedID,
                selectedEntryID: $selectedEntryID
            )
            .navigationTitle("Riverside")
        } detail: {
            if let selectedEntry {
                EntryContentView(entry: selectedEntry)
                    .id(selectedEntry.id)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 24) {
                    HStack(spacing: 4) {
                        SubscribeFeedButton {
                            Image(systemName: "plus")
                        }
                        
                        CloudSyncStateButton()
                        
                        let loading = cloudSyncState.syncing || foregroundRefreshState.isRefreshing
                        Button {
                            Task {
                                await foregroundRefreshState.refresh(
                                    context: context,
                                    cloudSyncState: cloudSyncState,
                                    force: true,
                                    timeout: .seconds(15),
                                    retryCount: 2
                                )
                            }
                        } label: {
                            if loading {
                                Image(systemName: "arrow.clockwise")
                                    .hidden()
                                    .overlay {
                                        ForegroundRefreshIndicator()
                                    }
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .disabled(loading)
                    }
                    
                    Toggle(isOn: $unreadOnly) {
                        Text("Unread only")
                    }
                    .toggleStyle(.checkbox)
                }
            }
        }
        .onForeground {
            Task {
                await foregroundRefreshState.refresh(
                    context: context,
                    cloudSyncState: cloudSyncState,
                    force: true,
                    timeout: .seconds(10)
                )
            }
        }
        .deleteDuplicatedEntriesOnBackground()
    }
}

#Preview {
    RootScreen()
}
