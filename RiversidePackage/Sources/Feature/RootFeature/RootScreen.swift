import Algorithms
import CoreData
import Dependencies
import Entities
import FeedUseCase
import FlashClient
import SwiftUI

@MainActor
public struct RootScreen: View {
    @AppStorage("unread-only") private var unreadOnly: Bool = true
    
    @Dependency(\.feedUseCase) private var feedUseCase
    @Dependency(\.flashClient) private var flashClient
    
    @Environment(\.managedObjectContext) private var context
    
    @State private var selectedFeedID: ObjectIdentifier? = nil
    @State private var selectedEntryID: ObjectIdentifier? = nil
    @State private var refreshing: Bool = false
    
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
                        
                        Button {
                            Task {
                                refreshing = true
                                defer { refreshing = false }
                                do {
                                    try await feedUseCase.addNewEpisodesForAllFeeds(context, true)
                                } catch {
                                    flashClient.present(
                                        type: .error,
                                        message: "Failed to refresh feeds: \(error.localizedDescription)"
                                    )
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(refreshing)
                    }
                    
                    Toggle(isOn: $unreadOnly) {
                        Text("Unread only")
                    }
                    .toggleStyle(.checkbox)
                }
            }
        }
        .onForeground { @MainActor in
            do {
                try await feedUseCase.addNewEpisodesForAllFeeds(context, false)
            } catch {
                print(error)
            }
        }
        // TODO: 重複したレコードを削除する
    }
}

#Preview {
    RootScreen()
}
