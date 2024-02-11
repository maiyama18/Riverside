import AddNewEntriesUseCase
import Algorithms
import CoreData
import CloudSyncState
import Dependencies
import Entities
import FlashClient
import SwiftUI
import ViewModifiers

@MainActor
public struct RootScreen: View {
    @AppStorage("unread-only") private var unreadOnly: Bool = true
    
    @Dependency(\.addNewEntriesUseCase) private var addNewEntriesUseCase
    @Dependency(\.flashClient) private var flashClient
    
    @Environment(CloudSyncState.self) private var cloudSyncState
    @Environment(\.managedObjectContext) private var context
    
    @State private var selectedFeedID: ObjectIdentifier? = nil
    @State private var selectedEntryID: ObjectIdentifier? = nil
    @State private var refreshing: Bool = false
    @State private var loadingAllFeedsOnForeground: Bool = false
    
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
                        
                        let loading = refreshing || cloudSyncState.syncing || loadingAllFeedsOnForeground
                        Button {
                            Task {
                                refreshing = true
                                defer { refreshing = false }
                                do {
                                    try await addNewEntriesUseCase.executeForAllFeeds(context, true)
                                } catch {
                                    flashClient.present(
                                        type: .error,
                                        message: "Failed to refresh feeds: \(error.localizedDescription)"
                                    )
                                }
                            }
                        } label: {
                            if loading {
                                Image(systemName: "arrow.clockwise")
                                    .hidden()
                                    .overlay {
                                        ProgressView()
                                            .controlSize(.small)
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
        .addNewEntriesForAllFeeds(loading: $loadingAllFeedsOnForeground)
        .deleteDuplicatedEntriesOnce()
    }
}

#Preview {
    RootScreen()
}
